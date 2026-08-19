# MapBanai - Team Agents & Roles

## Overview
This document defines specialized agents and their responsibilities for developing MapBanai.

---

## 1. ARCHITECT
**Responsibility:** System design and architecture decisions

- Design overall system architecture
- Define module boundaries and dependencies
- Review design proposals
- Ensure modularity and extensibility
- Technology stack decisions
- Code organization and structure

**Key Deliverables:**
- ARCHITECTURE.md
- Module dependency diagrams
- Technology recommendations

---

## 2. BACKEND/DATA ENGINEER
**Responsibility:** Data model, database, and sync infrastructure

- Design data models (Project, Survey, Feature, etc.)
- Implement local database (SQLite via Drift/Hive)
- Implement sync provider interface
- Handle GeoPackage import/export
- Manage offline-first data strategies
- Implement conflict resolution

**Key Deliverables:**
- DATA_MODEL.md
- Database schema
- Sync infrastructure code
- Data export/import utilities

---

## 3. FRONTEND ENGINEER
**Responsibility:** UI/UX implementation

- Implement Survey Mode UI (simple, large buttons)
- Implement GIS Mode UI (map, layers, editing)
- Navigation structure
- Compose UI components
- Responsive design
- Accessibility

**Key Deliverables:**
- Navigation structure
- Compose UI screens
- State management implementation
- User interaction flows

---

## 4. GIS ENGINEER
**Responsibility:** Map and spatial features

- MapLibre integration
- Basemap management
- Feature rendering
- GIS editing tools (point/line/polygon)
- Coordinate system handling
- GeoPackage integration

**Key Deliverables:**
- Map layer implementations
- Editing tools
- Spatial data utilities
- Basemap providers

---

## 5. GNSS/LOCATION ENGINEER
**Responsibility:** Location and GNSS functionality

- Android location APIs integration
- GNSS status monitoring
- Accuracy filtering system
- Location recording logic
- Satellite tracking
- GPS diagnostics display

**Key Deliverables:**
- Location manager utilities
- Accuracy filter implementation
- GNSS status handling
- Diagnostic tools

---

## 6. SURVEY ENGINEER
**Responsibility:** Survey system and form handling

- Survey schema design and validation
- Conditional logic engine
- Question type handlers
- Form rendering
- Survey import/export (JSON)
- Validation rules

**Key Deliverables:**
- Survey schema specification
- Question type implementations
- Conditional logic engine
- Form validation system

---

## 7. QA & TEST ENGINEER
**Responsibility:** Testing and quality assurance

- Unit test suite
- Integration tests
- Field testing protocols
- Bug tracking
- Performance profiling
- Offline scenario testing

**Key Deliverables:**
- TEST_PLAN.md
- Test suites
- CI/CD configuration
- Quality metrics

---

## 8. DEVOPS/BUILD ENGINEER
**Responsibility:** Build, deployment, and infrastructure

- Build system (Gradle)
- APK generation and signing
- Dependency management
- CI/CD pipeline
- Local development environment setup
- ADB/installation utilities

**Key Deliverables:**
- Build configuration
- Release procedures
- Installation guides
- Environment setup documentation

---

## 9. LOCALIZATION ENGINEER
**Responsibility:** Internationalization and localization

- String resource management
- Bangla language support
- RTL considerations (if needed)
- Translation workflows
- Regional settings

**Key Deliverables:**
- Localization architecture
- String resources
- Language-specific guides

---

## Decision Making

- **Architecture decisions:** ARCHITECT + Tech Lead consensus
- **Data model changes:** BACKEND ENGINEER + ARCHITECT review
- **UI decisions:** FRONTEND ENGINEER + UX input
- **Feature additions:** Full team technical review

---

## Communication
- Daily standups on critical path items
- Technical reviews for major PRs
- Weekly architecture sync
