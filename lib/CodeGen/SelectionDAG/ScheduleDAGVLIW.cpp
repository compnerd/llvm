//===- ScheduleDAGVLIW.cpp - SelectionDAG list scheduler for VLIW -*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This implements a top-down list scheduler, using standard algorithms.
// The basic approach uses a priority queue of available nodes to schedule.
// One at a time, nodes are taken from the priority queue (thus in priority
// order), checked for legality to schedule, and emitted if legal.
//
// Nodes may not be legal to schedule either due to structural hazards (e.g.
// pipeline or resource constraints) or because an input to the instruction has
// not completed execution.
//
//===----------------------------------------------------------------------===//

#include "llvm/CodeGen/SchedulerRegistry.h"
#include "ScheduleDAGSDNodes.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/LatencyPriorityQueue.h"
#include "llvm/CodeGen/ResourcePriorityQueue.h"
#include "llvm/CodeGen/ScheduleHazardRecognizer.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Target/TargetRegisterInfo.h"
#include <climits>
using namespace llvm;

#define DEBUG_TYPE "pre-RA-sched"

STATISTIC(NumNoops , "Number of noops inserted");
STATISTIC(NumStalls, "Number of pipeline stalls");

static RegisterScheduler
  VLIWScheduler("vliw-td", "VLIW scheduler",
                createVLIWDAGScheduler);

namespace {
//===----------------------------------------------------------------------===//
/// ScheduleDAGVLIW - The actual DFA list scheduler implementation.  This
/// supports / top-down scheduling.
///
class ScheduleDAGVLIW : public ScheduleDAGSDNodes {
private:
  /// AvailableQueue - The priority queue to use for the available SUnits.
  ///
  SchedulingPriorityQueue *AvailableQueue;

  /// PendingQueue - This contains all of the instructions whose operands have
  /// been issued, but their results are not ready yet (due to the latency of
  /// the operation).  Once the operands become available, the instruction is
  /// added to the AvailableQueue.
  std::vector<SUnit*> PendingQueue;

  /// HazardRec - The hazard recognizer to use.
  ScheduleHazardRecognizer *HazardRec;

  /// AA - AliasAnalysis for making memory reference queries.
  AliasAnalysis *AA;

public:
  ScheduleDAGVLIW(MachineFunction &mf,
                  AliasAnalysis *aa,
                  SchedulingPriorityQueue *availqueue)
    : ScheduleDAGSDNodes(mf), AvailableQueue(availqueue), AA(aa) {

    const TargetMachine &tm = mf.getTarget();
    HazardRec = tm.getInstrInfo()->CreateTargetHazardRecognizer(&tm, this);
  }

  ~ScheduleDAGVLIW() {
    delete HazardRec;
    delete AvailableQueue;
  }

  void Schedule() override;

private:
  void releaseSucc(SUnit *SU, const SDep &D);
  void releaseSuccessors(SUnit *SU);
  void scheduleNodeTopDown(SUnit *SU, unsigned CurCycle);
  void listScheduleTopDown();
};
}  // end anonymous namespace

/// Schedule - Schedule the DAG using list scheduling.
void ScheduleDAGVLIW::Schedule() {
  DEBUG(dbgs()
        << "********** List Scheduling BB#" << BB->getNumber()
        << " '" << BB->getName() << "' **********\n");

  // Build the scheduling graph.
  BuildSchedGraph(AA);

  AvailableQueue->initNodes(SUnits);

  listScheduleTopDown();

  AvailableQueue->releaseState();
}

//===----------------------------------------------------------------------===//
//  Top-Down Scheduling
//===----------------------------------------------------------------------===//

/// releaseSucc - Decrement the NumPredsLeft count of a successor. Add it to
/// the PendingQueue if the count reaches zero. Also update its cycle bound.
void ScheduleDAGVLIW::releaseSucc(SUnit *SU, const SDep &D) {
  SUnit *SuccSU = D.getSUnit();

#ifndef NDEBUG
  if (SuccSU->NumPredsLeft == 0) {
    dbgs() << "*** Scheduling failed! ***\n";
    SuccSU->dump(this);
    dbgs() << " has been released too many times!\n";
    llvm_unreachable(nullptr);
  }
#endif
  assert(!D.isWeak() && "unexpected artificial DAG edge");

  --SuccSU->NumPredsLeft;

  SuccSU->setDepthToAtLeast(SU->getDepth() + D.getLatency());

  // If all the node's predecessors are scheduled, this node is ready
  // to be scheduled. Ignore the special ExitSU node.
  if (SuccSU->NumPredsLeft == 0 && SuccSU != &ExitSU) {
    PendingQueue.push_back(SuccSU);
  }
}

void ScheduleDAGVLIW::releaseSuccessors(SUnit *SU) {
  // Top down: release successors.
  for (SUnit::succ_iterator I = SU->Succs.begin(), E = SU->Succs.end();
       I != E; ++I) {
    assert(!I->isAssignedRegDep() &&
           "The list-td scheduler doesn't yet support physreg dependencies!");

    releaseSucc(SU, *I);
  }
}

/// scheduleNodeTopDown - Add the node to the schedule. Decrement the pending
/// count of its successors. If a successor pending count is zero, add it to
/// the Available queue.
void ScheduleDAGVLIW::scheduleNodeTopDown(SUnit *SU, unsigned CurCycle) {
  DEBUG(dbgs() << "*** Scheduling [" << CurCycle << "]: ");
  DEBUG(SU->dump(this));

  Sequence.push_back(SU);
  assert(CurCycle >= SU->getDepth() && "Node scheduled above its depth!");
  SU->setDepthToAtLeast(CurCycle);

  releaseSuccessors(SU);
  SU->isScheduled = true;
  AvailableQueue->scheduledNode(SU);
}

/// listScheduleTopDown - The main loop of list scheduling for top-down
/// schedulers.
void ScheduleDAGVLIW::listScheduleTopDown() {
  unsigned CurCycle = 0;

  // Release any successors of the special Entry node.
  releaseSuccessors(&EntrySU);

  // All leaves to AvailableQueue.
  for (unsigned i = 0, e = SUnits.size(); i != e; ++i) {
    // It is available if it has no predecessors.
    if (SUnits[i].Preds.empty()) {
      AvailableQueue->push(&SUnits[i]);
      SUnits[i].isAvailable = true;
    }
  }

  // While AvailableQueue is not empty, grab the node with the highest
  // priority. If it is not ready put it back.  Schedule the node.
  std::vector<SUnit*> NotReady;
  Sequence.reserve(SUnits.size());
  while (!AvailableQueue->empty() || !PendingQueue.empty()) {
    // Check to see if any of the pending instructions are ready to issue.  If
    // so, add them to the available queue.
    for (unsigned i = 0, e = PendingQueue.size(); i != e; ++i) {
      if (PendingQueue[i]->getDepth() == CurCycle) {
        AvailableQueue->push(PendingQueue[i]);
        PendingQueue[i]->isAvailable = true;
        PendingQueue[i] = PendingQueue.back();
        PendingQueue.pop_back();
        --i; --e;
      }
      else {
        assert(PendingQueue[i]->getDepth() > CurCycle && "Negative latency?");
      }
    }

    // If there are no instructions available, don't try to issue anything, and
    // don't advance the hazard recognizer.
    if (AvailableQueue->empty()) {
      // Reset DFA state.
      AvailableQueue->scheduledNode(nullptr);
      ++CurCycle;
      continue;
    }

    SUnit *FoundSUnit = nullptr;

    bool HasNoopHazards = false;
    while (!AvailableQueue->empty()) {
      SUnit *CurSUnit = AvailableQueue->pop();

      ScheduleHazardRecognizer::HazardType HT =
        HazardRec->getHazardType(CurSUnit, 0/*no stalls*/);
      if (HT == ScheduleHazardRecognizer::NoHazard) {
        FoundSUnit = CurSUnit;
        break;
      }

      // Remember if this is a noop hazard.
      HasNoopHazards |= HT == ScheduleHazardRecognizer::NoopHazard;

      NotReady.push_back(CurSUnit);
    }

    // Add the nodes that aren't ready back onto the available list.
    if (!NotReady.empty()) {
      AvailableQueue->push_all(NotReady);
      NotReady.clear();
    }

    // If we found a node to schedule, do it now.
    if (FoundSUnit) {
      scheduleNodeTopDown(FoundSUnit, CurCycle);
      HazardRec->EmitInstruction(FoundSUnit);

      // If this is a pseudo-op node, we don't want to increment the current
      // cycle.
      if (FoundSUnit->Latency)  // Don't increment CurCycle for pseudo-ops!
        ++CurCycle;
    } else if (!HasNoopHazards) {
      // Otherwise, we have a pipeline stall, but no other problem, just advance
      // the current cycle and try again.
      DEBUG(dbgs() << "*** Advancing cycle, no work to do\n");
      HazardRec->AdvanceCycle();
      ++NumStalls;
      ++CurCycle;
    } else {
      // Otherwise, we have no instructions to issue and we have instructions
      // that will fault if we don't do this right.  This is the case for
      // processors without pipeline interlocks and other cases.
      DEBUG(dbgs() << "*** Emitting noop\n");
      HazardRec->EmitNoop();
      Sequence.push_back(nullptr);   // NULL here means noop
      ++NumNoops;
      ++CurCycle;
    }
  }

#ifndef NDEBUG
  VerifyScheduledSequence(/*isBottomUp=*/false);
#endif
}

//===----------------------------------------------------------------------===//
//                         Public Constructor Functions
//===----------------------------------------------------------------------===//

/// createVLIWDAGScheduler - This creates a top-down list scheduler.
ScheduleDAGSDNodes *
llvm::createVLIWDAGScheduler(SelectionDAGISel *IS, CodeGenOpt::Level) {
  return new ScheduleDAGVLIW(*IS->MF, IS->AA, new ResourcePriorityQueue(IS));
}
