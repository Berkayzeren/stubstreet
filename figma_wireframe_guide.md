# Figma Wireframe Specifications & Workshop Facilitation Guide

## Workshop Facilitation Script

### Opening (5 minutes)
**"Good morning everyone. Today we're going to define the requirements for two critical features: real-time messaging and rich profile pages. Our goal is to walk away with clear user stories, acceptance criteria, and wireframe specifications that our design and development teams can execute on."**

### Icebreaker Activity (10 minutes)
**"Let's start by sharing: What's your favorite messaging app and why? What makes a profile page compelling to you?"**

### Context Setting Questions (15 minutes)
Guide the team through these discovery questions:

1. **"Who is our primary user persona, and what are their key messaging needs?"**
2. **"What scale are we designing for - 100 users, 10,000, or 100,000?"**
3. **"What devices and platforms must we support?"**
4. **"What are our performance expectations for message delivery?"**
5. **"What privacy and security requirements do we need to consider?"**

---

## Real-time Messaging Workshop Deep Dive

### Facilitation Questions for Messaging Features

#### Core Messaging Discovery
**"Let's map out the user journey for sending their first message:"**

1. **Message Composition**
   - How does a user start a new conversation?
   - What input methods do we support? (text, voice-to-text, attachments)
   - Should we have message length limits?
   - Do we need message formatting options?

2. **Message Delivery**
   - What happens when a message is sent?
   - How do we handle network failures?
   - Should users see delivery confirmations?
   - What about read receipts?

3. **Conversation Management**
   - How are conversations organized?
   - Should we support conversation search?
   - What about message history and persistence?
   - How do we handle message deletion?

#### Group Messaging Deep Dive
**"Now let's think about group conversations:"**

1. **Group Creation & Management**
   - Who can create groups?
   - How many participants should we allow?
   - What admin permissions do we need?
   - Should we support group descriptions/themes?

2. **Group Interactions**
   - How do mentions work in groups?
   - Do we need thread support for replies?
   - Should we have different notification settings for groups?
   - How do we handle users leaving/being removed?

---

## Rich Profile Page Workshop Deep Dive

### Facilitation Questions for Profile Features

#### Profile Information Architecture
**"Let's design the ideal profile page together:"**

1. **Essential Information**
   - What information is absolutely required?
   - What's optional but valuable?
   - How do we balance information richness with simplicity?
   - What privacy controls do users need?

2. **Visual Elements**
   - How important are profile photos?
   - Should we support cover photos?
   - What about photo galleries or portfolios?
   - How do we handle image optimization?

3. **Social Features**
   - Do we need follower/following functionality?
   - Should profiles show activity or stats?
   - How do we handle profile verification?
   - What social links should we support?

#### Profile Customization & Privacy
**"Let's talk about user control and privacy:"**

1. **Customization Options**
   - Should users be able to customize their profile layout?
   - Do we need theme options?
   - How much control over visibility should users have?
   - Should we support profile sections or tabs?

2. **Privacy Controls**
   - What granular privacy settings do we need?
   - How do we handle profile visibility to non-friends?
   - Should we have privacy presets (public, friends-only, private)?
   - How do we communicate privacy settings to users?

---

## Detailed Figma Wireframe Specifications

### Real-time Messaging Wireframes

#### 1. Chat List View (Main Messaging Screen)
**Artboard Size:** 375x812 (Mobile), 1440x1024 (Desktop)

**Components to Include:**
```
Header Section:
- App title/logo
- Search icon
- New message button (+)
- User profile avatar (small)

Conversation List:
- Contact avatar (40x40px)
- Contact name (16px, bold)
- Last message preview (14px, gray)
- Timestamp (12px, light gray)
- Unread badge (red circle with count)
- Online status indicator (green dot)

Bottom Navigation:
- Messages tab (active)
- Profile tab
- Settings tab
```

**Interaction States:**
- Default state
- Search active state
- Long press/swipe actions (delete, archive)
- Empty state (no conversations)

#### 2. Conversation View (Individual Chat)
**Artboard Size:** 375x812 (Mobile), 1440x1024 (Desktop)

**Components to Include:**
```
Header Section:
- Back button
- Contact avatar (32x32px)
- Contact name + online status
- More options menu (...)

Message Thread:
- Message bubbles (sent vs received styling)
- Timestamp (below messages)
- Message status indicators (✓, ✓✓, ✓✓ blue)
- System messages (user joined, etc.)
- Message reactions (emoji)

Input Section:
- Text input field
- Attachment button (📎)
- Emoji button (😊)
- Send button (➤)
- Typing indicator
```

**Message Bubble Specifications:**
- Sent messages: Right-aligned, primary color background
- Received messages: Left-aligned, light gray background
- Max width: 70% of screen width
- Padding: 12px horizontal, 8px vertical
- Border radius: 18px

#### 3. Group Chat Management
**Artboard Size:** 375x812 (Mobile)

**Components to Include:**
```
Group Info Header:
- Group avatar (80x80px)
- Group name (editable)
- Participant count
- Group description

Participant List:
- Participant avatar (40x40px)
- Participant name
- Admin badge (if applicable)
- Online status
- Remove/make admin actions

Group Settings:
- Notification settings
- Media sharing permissions
- Group privacy settings
- Leave group option
```

### Rich Profile Page Wireframes

#### 1. Profile Overview (View Mode)
**Artboard Size:** 375x812 (Mobile), 1440x1024 (Desktop)

**Components to Include:**
```
Header Section:
- Cover photo (375x200px mobile, 1440x300px desktop)
- Profile avatar (120x120px, overlapping cover)
- Edit profile button (if own profile)
- Message/Follow button (if other's profile)

Basic Information:
- Display name (24px, bold)
- Username (@username) (16px, gray)
- Bio text (16px, max 3 lines)
- Location (14px, with icon)
- Join date (14px, gray)

Stats Row:
- Posts count
- Followers count
- Following count

Content Sections:
- About section
- Photos gallery
- Social links
- Interests/Skills tags
- Verification badges
```

#### 2. Profile Edit Mode
**Artboard Size:** 375x812 (Mobile)

**Components to Include:**
```
Header:
- Cancel button
- "Edit Profile" title
- Save button (primary color)

Editable Fields:
- Cover photo upload area
- Avatar upload area
- Name input field
- Bio textarea (character counter)
- Location input field
- Website URL field
- Social media links

Privacy Controls:
- Profile visibility toggle
- Individual field privacy settings
- Who can message you settings
- Who can see your activity

Photo Management:
- Current photos grid
- Add photos button
- Delete/reorder photos
- Photo privacy settings
```

#### 3. Mobile Profile Views
**Artboard Size:** 375x812

**Key Responsive Considerations:**
- Stack information vertically
- Collapsible sections for long content
- Touch-friendly button sizes (44x44px minimum)
- Optimized image sizes for mobile
- Bottom sheet for actions menu

---

## Wireframe Component Library

### Design System Elements to Create

#### Typography Scale
```
- Heading 1: 32px, Bold
- Heading 2: 24px, Bold
- Heading 3: 20px, Semi-bold
- Body Text: 16px, Regular
- Caption: 14px, Regular
- Small Text: 12px, Regular
```

#### Color Palette
```
Primary Colors:
- Primary: #007AFF (action buttons, active states)
- Secondary: #5856D6 (accent elements)

Neutral Colors:
- Text Primary: #000000
- Text Secondary: #666666
- Text Tertiary: #999999
- Background: #FFFFFF
- Background Secondary: #F8F9FA
- Border: #E5E5E5

Status Colors:
- Success: #34C759 (online, delivered)
- Warning: #FF9500 (pending)
- Error: #FF3B30 (failed, delete)
- Info: #007AFF (information)
```

#### Component States
```
Button States:
- Default
- Hover
- Pressed
- Disabled
- Loading

Input Field States:
- Empty
- Focused
- Filled
- Error
- Disabled

Message States:
- Sending
- Sent
- Delivered
- Read
- Failed
```

---

## Workshop Output Templates

### User Story Template
```
Title: [Feature Name]
As a [user type]
I want to [action/capability]
So that [benefit/value]

Acceptance Criteria:
- [ ] [Specific, measurable requirement]
- [ ] [Specific, measurable requirement]
- [ ] [Specific, measurable requirement]

Priority: [High/Medium/Low]
Effort: [Small/Medium/Large]
Dependencies: [List any dependencies]
```

### Technical Requirement Template
```
Requirement: [Name]
Type: [Functional/Non-functional]
Description: [Detailed description]
Acceptance Criteria: [How to verify]
Priority: [Must have/Should have/Could have]
Technical Notes: [Implementation considerations]
```

---

## Workshop Facilitation Tips

### Managing Stakeholder Dynamics
- **Time management:** Use timers for each discussion segment
- **Parking lot:** Keep a visible list of items to discuss later
- **Decision making:** Use dot voting for prioritization
- **Consensus building:** Ensure all voices are heard

### Capturing Requirements Effectively
- **Visual aids:** Use sticky notes or digital equivalents
- **User journey mapping:** Walk through step-by-step flows
- **Edge cases:** Ask "what if" questions for each scenario
- **Constraints:** Document technical and business limitations

### Workshop Success Criteria
- [ ] All attendees understand the requirements
- [ ] Priorities are clearly established
- [ ] Acceptance criteria are specific and measurable
- [ ] Technical feasibility is confirmed
- [ ] Next steps are defined with owners

---

## Post-Workshop Action Items

### Immediate (Within 24 hours)
- [ ] Distribute workshop notes to all participants
- [ ] Create Figma wireframes based on specifications
- [ ] Schedule follow-up reviews with key stakeholders
- [ ] Begin technical spike for complex requirements

### Short-term (Within 1 week)
- [ ] Complete low-fidelity wireframes
- [ ] Technical architecture documentation
- [ ] User story refinement and backlog creation
- [ ] Testing strategy definition

### Medium-term (Within 2 weeks)
- [ ] High-fidelity mockups creation
- [ ] Development estimation and planning
- [ ] Sprint planning and task breakdown
- [ ] Stakeholder approval and sign-off

---

## Figma Organization Structure

### Recommended Page Structure
```
1. Workshop Notes & Requirements
2. User Journey Maps
3. Low-Fidelity Wireframes
   - Messaging Flows
   - Profile Flows
   - Mobile Views
4. Component Library
5. High-Fidelity Mockups (Future)
6. Prototypes (Future)
```

### File Naming Convention
```
- [Feature]_[Type]_[Version]
- Examples:
  - Messaging_Wireframe_v1
  - Profile_Component_v2
  - UserFlow_Journey_v1
```

This comprehensive workshop framework provides everything needed to successfully capture requirements, create user stories with acceptance criteria, and produce detailed wireframe specifications for both real-time messaging and rich profile pages.
