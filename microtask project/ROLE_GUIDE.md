# TaskNest - User Roles & Responsibilities Guide

## Role Comparison Matrix

| Feature | User | Business Lead |
|---------|------|---------------|
| **Login Type** | User Role Selected | Business Lead Role Selected |
| **Primary Goal** | Earn money by completing tasks | Manage tasks & budget |
| **Create Tasks** | ❌ No | ✅ Yes |
| **Accept Tasks** | ✅ Yes | ❌ No |
| **Submit Work** | ✅ Yes | ❌ No |
| **Review Submissions** | ❌ No | ✅ Yes |
| **Approve/Reject** | ❌ No | ✅ Yes |
| **Earn Money** | ✅ Yes | ❌ No (Controls Budget) |
| **Wallet Management** | View Balance | Allocate Budget |

---

## User Role - Complete Feature Set

### Dashboard Overview
```
USER DASHBOARD
├── Welcome Card (Balance Display)
├── Quick Actions
│   ├── Browse Tasks
│   ├── My Tasks
│   ├── Wallet
│   └── Profile
├── Your Tasks Section
│   ├── Shows accepted tasks
│   ├── Displays current status
│   │   ├── "Accepted" (Green) - User has accepted
│   │   ├── "Under Review" (Orange) - Work submitted, awaiting approval
│   │   └── "Completed" (Teal) - Approved & money earned
│   └── Reward amount for each task
└── Available Tasks Section
    ├── Shows open tasks from Business Leads
    ├── Task description & amount
    └── "Accept" button to take a task
```

### User Workflow (Step-by-Step)

**Step 1: Login**
- User selects "User" role on login screen
- Enters email and password
- Authenticates and lands on User Dashboard

**Step 2: Browse Available Tasks**
- User sees list of open tasks created by Business Leads
- Each task shows:
  - Task title
  - Full description
  - Reward amount (₹)
  - "Accept" button

**Step 3: Accept a Task**
- User clicks "Accept" button on a task
- Task immediately moved to "Your Tasks" section
- **Status shows "Accepted"** (Green badge)
- User now has the task assigned

**Step 4: Work on Task**
- User completes the assigned work
- Prepares submission (file, code, design, etc.)

**Step 5: Submit Work**
- User submits their completed work
- Status changes to **"Under Review"** (Orange badge)
- Business Lead receives notification for review

**Step 6: Wait for Approval**
- Business Lead reviews the submitted work
- Status remains "Under Review" until approval decision

**Step 7: Approval Outcomes**

| Outcome | Status | Action |
|---------|--------|--------|
| **Approved** | "Accepted" (Green) | Reward (₹) added to wallet |
| **Rejected** | "Rejected" (Red) | Can resubmit improved work |

### User Dashboard - Example Display

```
┌─────────────────────────────────────────────┐
│  Welcome back!                              │
│  Balance: ₹2,200                            │
└─────────────────────────────────────────────┘

QUICK ACTIONS:
[📋 Browse Tasks] [📝 My Tasks] [💰 Wallet] [👤 Profile]

YOUR TASKS:
┌─────────────────────────────────────────────┐
│ Website Redesign                            │
│ Complete redesign of company website        │
│ ₹1,500                [UNDER REVIEW 🟠]    │ ← Awaiting approval
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Content Writing                             │
│ Write blog posts for marketing              │
│ ₹800                  [ACCEPTED ✅]        │ ← Approved & earned
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ App Testing                                 │
│ Test mobile app for bugs                    │
│ ₹1,200                [COMPLETED ✔️]       │ ← Finished & completed
└─────────────────────────────────────────────┘

AVAILABLE TASKS:
┌─────────────────────────────────────────────┐
│ Logo Design                                 │
│ Design a modern logo for our brand          │
│ ₹2,000                         [ACCEPT ▶]  │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Social Media Graphics                       │
│ Create 10 graphics for social media         │
│ ₹1,500                         [ACCEPT ▶]  │
└─────────────────────────────────────────────┘
```

---

## Business Lead Role - Complete Feature Set

### Dashboard Overview
```
BUSINESS LEAD DASHBOARD
├── Welcome Card (Brand & Role Info)
├── Quick Actions
│   ├── Create Task
│   └── Review Submissions (with pending count)
├── Statistics Section
│   ├── Total Tasks Created
│   ├── Active Tasks
│   ├── Pending Reviews Count
│   └── Total Budget Allocated
├── Pending Reviews Section
│   ├── Shows submissions awaiting approval
│   ├── User work/submission details
│   ├── "Approve" button
│   └── "Reject" button
└── Active Tasks Section
    ├── Tasks assigned to users
    ├── Task status & rewards
    └── Budget tracking
```

### Business Lead Workflow (Step-by-Step)

**Step 1: Login**
- Business Lead selects "Business Lead" role on login screen
- Enters email and password
- Authenticates and lands on Business Lead Dashboard

**Step 2: Create a New Task**
- Click "Create Task" button
- Fill in task details:
  - Task Title
  - Detailed Description
  - Reward Amount (₹)
  - Task Category (optional)
- Submit task
- Task becomes available for users to accept

**Step 3: Monitor Submissions**
- Business Lead sees "Pending Reviews" section
- Each pending review shows:
  - Task name
  - User who submitted
  - Submission time
  - User's submitted work
  - Status: **"Under Review"** (Orange badge)

**Step 4: Review Submitted Work**
- Business Lead clicks on submission to review
- Examines user's work quality
- Checks if work meets requirements
- Makes decision: Approve or Reject

**Step 5: Approve Submission**
- Click "Approve" button
- Task status changes to **"Accepted"** (Green badge)
- User's reward amount is added to their wallet
- User receives notification of approval
- Task moves to "Completed" section

**Step 6: Reject Submission (Alternative)**
- Click "Reject" button
- Task status changes to **"Rejected"** (Red badge)
- User can view feedback/reason
- Task remains assigned - user can resubmit

**Step 7: View Statistics**
- Dashboard displays:
  - Total Tasks Created
  - Active Tasks (currently assigned)
  - Pending Reviews (waiting for decision)
  - Total Budget Used (sum of all task rewards)

### Business Lead Dashboard - Example Display

```
┌─────────────────────────────────────────────┐
│ Business Lead Dashboard                     │
│ Manage tasks and review submissions         │
└─────────────────────────────────────────────┘

QUICK ACTIONS:
[➕ Create Task] [✅ Review Submissions (2)]

STATISTICS:
┌─────┐ ┌──────┐ ┌─────────┐ ┌────────┐
│  4  │ │  2   │ │    2    │ │ ₹5,500 │
│Total│ │Active│ │ Pending │ │ Budget │
│Task │ │ Task │ │ Reviews │ │ Used   │
└─────┘ └──────┘ └─────────┘ └────────┘

PENDING REVIEWS:
┌─────────────────────────────────────────────┐
│ Website Redesign           [UNDER REVIEW 🟠]│
│ ₹1,500                                      │
│              [REJECT ❌]  [APPROVE ✅]      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Content Writing            [UNDER REVIEW 🟠]│
│ ₹800                                        │
│              [REJECT ❌]  [APPROVE ✅]      │
└─────────────────────────────────────────────┘

ACTIVE TASKS:
┌─────────────────────────────────────────────┐
│ Logo Design                   [ACCEPTED ✅] │
│ ₹2,000                                      │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ App Testing                   [ACCEPTED ✅] │
│ ₹1,200                                      │
└─────────────────────────────────────────────┘
```

---

## Task Status Lifecycle

### From User Perspective
```
BROWSE AVAILABLE
      ↓
   ACCEPT ← User clicks Accept button
      ↓
STATUS: "ACCEPTED" ← Task is now mine
      ↓
   WORK ON TASK ← User completes work
      ↓
   SUBMIT WORK ← User submits completed work
      ↓
STATUS: "UNDER REVIEW" 🟠 ← Waiting for BL approval
      ↓
   WAIT FOR DECISION ← BL reviews work
      ↓
APPROVE? ├─→ YES → STATUS: "ACCEPTED" + ✅ Earn ₹
         │
         └─→ NO → STATUS: "REJECTED" + 🔴 Can Resubmit
```

### From Business Lead Perspective
```
CREATE TASK ← Click "Create Task" button
      ↓
PUBLISHED ← Available for users
      ↓
USERS ACCEPT ← Users take the task
      ↓
AWAIT SUBMISSIONS ← Wait for users to submit work
      ↓
SUBMISSION RECEIVED
      ↓
STATUS: "UNDER REVIEW" 🟠 ← Ready for review
      ↓
   REVIEW WORK ← Check quality & requirements
      ↓
DECISION ├─→ APPROVE → Transfer money to user wallet
         │
         └─→ REJECT → Allow user to resubmit
```

---

## Key Differences

### Task Acceptance
- **User**: "I want this task" → Click Accept
- **Business Lead**: Creates tasks that users can accept

### Status Control
- **User**: Can only see their task status
- **Business Lead**: Controls task status through approval/rejection

### Money Flow
- **User**: Earn money when Business Lead approves their work
- **Business Lead**: Allocate budget to tasks, deduct when users complete

### Notifications
- **User**: Gets notified when BL approves/rejects work
- **Business Lead**: Gets notified when user submits work for review

### Dashboard Focus
- **User**: Focus on earning and task progress
- **Business Lead**: Focus on task management and review backlog

---

## Status Badge Reference

### User's View
```
┌──────────────────────────────────┐
│ ACCEPTED (Green) ✅              │
│ Task is mine, I'm working on it  │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ UNDER REVIEW (Orange) 🟠         │
│ I submitted, waiting for approval│
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ COMPLETED (Teal) ✔️              │
│ Approved! Money earned           │
└──────────────────────────────────┘
```

### Business Lead's View
```
┌──────────────────────────────────┐
│ OPEN (Blue) 📘                   │
│ Available for users to accept    │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ ACCEPTED (Green) ✅              │
│ User is working on this task     │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ UNDER REVIEW (Orange) 🟠         │
│ User submitted, needs my review  │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ COMPLETED (Teal) ✔️              │
│ I approved, user earned money    │
└──────────────────────────────────┘
```

---

## Example Scenarios

### Scenario 1: Happy Path (Approval)
```
Day 1:
  BL: Creates "Logo Design" task, ₹2,000
  
Day 2:
  User: Accepts "Logo Design" task
  Status: ACCEPTED ✅
  
Day 5:
  User: Completes logo, submits work
  Status: UNDER REVIEW 🟠
  
Day 6:
  BL: Reviews logo, approves quality
  Status: ACCEPTED ✅
  User: Receives ₹2,000 in wallet
```

### Scenario 2: Rejection & Resubmission
```
Day 1:
  BL: Creates "Content Writing" task, ₹800
  
Day 2:
  User: Accepts "Content Writing" task
  Status: ACCEPTED ✅
  
Day 4:
  User: Submits first draft
  Status: UNDER REVIEW 🟠
  
Day 5:
  BL: Rejects (needs better research)
  Status: REJECTED 🔴
  User: Notified with feedback
  
Day 6:
  User: Resubmits improved content
  Status: UNDER REVIEW 🟠
  
Day 7:
  BL: Approves improved content
  Status: ACCEPTED ✅
  User: Receives ₹800 in wallet
```

### Scenario 3: Multiple Concurrent Tasks
```
User has 3 tasks:
  1. Website Redesign - UNDER REVIEW 🟠 (₹1,500)
  2. Content Writing - ACCEPTED ✅ (₹800)
  3. App Testing - COMPLETED ✔️ (₹1,200)

Earnings: ₹1,200 (from #3 only)
Potential: ₹3,500 (if all approved)

BL receives notification when:
  - #1 reaches "UNDER REVIEW"
  - #2 is completed and submitted
```

