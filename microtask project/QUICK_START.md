# TaskNest - Quick Start Guide

## 🚀 Quick Setup & Testing

### Files Modified/Created
✅ `lib/models/user_model.dart` - Added UserRole enum  
✅ `lib/models/task_model.dart` - New Task model with status  
✅ `lib/services/user_service.dart` - Added role management  
✅ `lib/screens/auth/login_screen.dart` - Redesigned with dual role selection  
✅ `lib/screens/home/home_screen.dart` - Updated user dashboard  
✅ `lib/screens/home/business_lead_screen.dart` - New business lead dashboard  
✅ `lib/main.dart` - Updated routing  

---

## 🎯 Testing the App

### Test as User
1. **Launch App** → Login Screen appears
2. **Select Role** → Click the "User" card (Blue)
3. **Enter Credentials**
   - Email: `user@example.com`
   - Password: `password123`
4. **Click Sign In** → User Dashboard loads
5. **Explore**
   - See "Your Tasks" with different statuses
   - See "Available Tasks" you can accept
   - Click "Accept" button to take a task
   - Check Wallet, Profile, etc.

### Test as Business Lead
1. **Launch App** → Login Screen appears
2. **Select Role** → Click the "Business Lead" card (Purple)
3. **Enter Credentials**
   - Email: `lead@example.com`
   - Password: `password123`
4. **Click Sign In** → Business Lead Dashboard loads
5. **Explore**
   - See statistics (Total, Active, Pending, Budget)
   - See "Pending Reviews" section with submissions
   - Click "Approve" or "Reject" buttons
   - Click "Create Task" to add new task

---

## 🎨 UI Features Highlights

### Login Screen
- **Dual Role Selection**: Click on "User" or "Business Lead" cards
- **Role Color Coding**: User (Blue), Business Lead (Purple)
- **Professional Design**: Clean, modern interface
- **Form Validation**: Email and password required

### User Dashboard
- **Welcome Card**: Shows current wallet balance
- **Quick Actions**: Easy access to main features
- **Your Tasks Section**: Shows accepted/in-progress tasks
- **Available Tasks Section**: Shows open tasks to accept
- **Status Badges**: Color-coded for quick understanding
  - 🟠 Orange = Under Review (awaiting approval)
  - 🟢 Green = Accepted (approved by BL)
  - 🔷 Teal = Completed (finished task)

### Business Lead Dashboard
- **Statistics Panel**: Key metrics at a glance
- **Pending Reviews**: Tasks needing approval
- **Active Tasks**: Currently assigned tasks
- **Quick Actions**: Create Task, Review Submissions
- **Approve/Reject**: Easy action buttons

---

## 📊 Status Flow Diagram

```
TASK LIFECYCLE:
┌─────────┐    ┌──────────┐    ┌─────────────┐    ┌────────┐    ┌──────────┐
│  OPEN   │ -> │ ACCEPTED │ -> │ UNDER REVIEW│ -> │ ────── │ -> │COMPLETED│
│ (Blue)  │    │ (Green)  │    │  (Orange)   │    │REJECTED│    │ (Teal)  │
└─────────┘    └──────────┘    └─────────────┘    │ (Red)  │    └──────────┘
                                                    └────────┘ (can resubmit)
```

---

## 💡 Key Features Implemented

### 1. Role-Based Authentication
```dart
enum UserRole { user, businessLead }
// Login determines which dashboard to show
```

### 2. Task Status Tracking
```dart
enum TaskStatus { 
  open,           // Available for users
  accepted,       // User has taken it
  underReview,    // Submitted, waiting for approval
  completed,      // Approved by BL
  rejected        // Rejected, can resubmit
}
```

### 3. Mock Data Ready
- Pre-populated tasks for testing
- Realistic user and business lead examples
- Sample submissions and reviews

### 4. Color-Coded UI
- User interface: Blue/Green colors
- Business Lead interface: Purple/Orange colors
- Status badges: Unique colors for each status

---

## 🔧 Code Structure

### Models Layer
```dart
// User with role
User {
  name, email, wallet, role ← NEW
}

// Tasks with full lifecycle
Task {
  id, title, description, amount, 
  createdBy, status ← NEW, 
  acceptedBy, timestamps
}
```

### Service Layer
```dart
UserService {
  userRole ← NEW getter
  isBusinessLead ← NEW getter
  setUser(..., userRole) ← Updated
}
```

### Screen Layer
```
LoginScreen
  ├─ Role Selection UI ← NEW
  └─ Role-based routing

HomeScreen (User)
  ├─ Your Tasks Section
  ├─ Available Tasks Section
  └─ Status Badges

BusinessLeadScreen (BL) ← NEW
  ├─ Create Task
  ├─ Pending Reviews
  ├─ Active Tasks
  └─ Statistics
```

---

## 🎯 User Journey Map

### User Flow
```
1. Open App
   ↓
2. Select "User" Role
   ↓
3. Login with credentials
   ↓
4. See User Dashboard
   ├─ Wallet Balance: ₹2,200
   ├─ Your Tasks: 3 tasks (various statuses)
   └─ Available Tasks: 2 open tasks
   ↓
5. Accept Available Task
   ↓
6. Status changes to "Accepted"
   ↓
7. Work on task...
   ↓
8. Submit Work
   ↓
9. Status changes to "Under Review" 🟠
   ↓
10. Wait for Business Lead approval
    ├─ If Approved → Earn Money ✅
    └─ If Rejected → Resubmit 🔴
```

### Business Lead Flow
```
1. Open App
   ↓
2. Select "Business Lead" Role
   ↓
3. Login with credentials
   ↓
4. See BL Dashboard
   ├─ Statistics: 4 Tasks, 2 Active, 2 Pending, ₹5,500 Budget
   ├─ Pending Reviews: 2 submissions waiting
   └─ Active Tasks: 2 tasks assigned to users
   ↓
5. Create New Task
   ├─ Title: "Logo Design"
   ├─ Description: "Design modern logo"
   └─ Amount: ₹2,000
   ↓
6. Publish Task (becomes available)
   ↓
7. Users accept the task
   ↓
8. User submits work
   ↓
9. Notification: Pending Review 🟠
   ↓
10. Review Work
    ├─ Click "Approve" → Transfer money to wallet ✅
    └─ Click "Reject" → User can resubmit 🔴
```

---

## 📱 Screen Navigation Map

```
Login Screen
├─ User Login → User Dashboard
│  ├─ Browse Tasks
│  ├─ My Tasks
│  ├─ Wallet
│  └─ Profile
│
└─ BL Login → Business Lead Dashboard
   ├─ Create Task
   ├─ Pending Reviews
   ├─ Active Tasks
   └─ Statistics
```

---

## 🎨 Color Palette Reference

### UI Colors
```
User Interface:
- Primary: Blue (#1976D2)
- Accent: Green (#4CAF50), Orange (#FF9800)
- Background: Light Gray (#F5F6FA)

Business Lead Interface:
- Primary: Deep Purple (#7B1FA2)
- Accent: Orange (#FF9800), Red (#F44336)
- Background: Light Gray (#F5F6FA)
```

### Status Colors
```
Open:       Blue (#1976D2)    - Available
Accepted:   Green (#4CAF50)   - Approved/Assigned
UnderReview:Orange (#FF9800)  - Pending Decision
Completed:  Teal (#009688)    - Done
Rejected:   Red (#F44336)     - Failed
```

---

## 🚀 Next Steps for Integration

### 1. Backend API Integration
```dart
// Replace mock data with API calls
// Examples in api_service.dart:
- POST /auth/login (with role parameter)
- POST /tasks/create
- POST /tasks/accept
- POST /tasks/review (approve/reject)
- GET /user/tasks
- GET /tasks/available
```

### 2. Database Schema
```sql
Users table:
- id, name, email, password, wallet, role (user/businessLead)

Tasks table:
- id, title, description, amount, createdBy (BL), status, 
  acceptedBy (User), timestamps

Transactions table:
- id, userId, taskId, amount, type (earn/deduct)
```

### 3. State Management (Optional)
- Consider using Provider or GetX for better state management
- Replace StatefulWidget with more scalable solutions
- Implement proper error handling and loading states

### 4. Features to Add
- [ ] File upload for task submissions
- [ ] Rating system for completed tasks
- [ ] Task categories and filtering
- [ ] Real-time notifications
- [ ] Payment gateway integration
- [ ] Task history and analytics
- [ ] User feedback and comments

---

## 📝 Testing Checklist

- [ ] Login with User role selected → User dashboard loads
- [ ] Login with Business Lead role selected → BL dashboard loads
- [ ] User can see available tasks
- [ ] User can accept a task (status changes)
- [ ] BL can see pending reviews
- [ ] BL can approve/reject submissions
- [ ] Status badges display with correct colors
- [ ] Wallet balance displays correctly
- [ ] Statistics update correctly on BL dashboard
- [ ] UI is responsive on different screen sizes
- [ ] No console errors in Flutter DevTools

---

## ❓ FAQ

**Q: How do users earn money?**  
A: When a Business Lead approves their submitted work, the reward amount is added to their wallet.

**Q: Can a user create tasks?**  
A: No, only Business Leads can create tasks. Users can only accept and complete them.

**Q: What happens if a Business Lead rejects work?**  
A: The task status becomes "Rejected" and the user can resubmit improved work.

**Q: Can a user see other users' tasks?**  
A: No, users only see available tasks to accept and their own accepted tasks.

**Q: Can a Business Lead see user details?**  
A: In the current implementation, only task submissions are visible. User profiles can be added later.

**Q: How is task completion tracked?**  
A: When a user submits work, it goes to "Under Review". BL approves/rejects from there.

---

## 📞 Support & Documentation

For more details, see:
- `IMPLEMENTATION_GUIDE.md` - Complete implementation overview
- `ARCHITECTURE_GUIDE.md` - System architecture and data models
- `ROLE_GUIDE.md` - Detailed role responsibilities and workflows

