- Integration Patterns
 	- Creational Patterns
  		- Abstract Factory
  		- Builder
  		- Factory Method
  		- Prototype
  		- Singleton
		- Object Pool
		- Immutable Objects
 	- Structural Patterns
  		- Adapter
  		- Bridge
  		- Composite
  		- Decorator
  		- Facade
  		- Flyweight
  		- Private Class Data
  		- Proxy
 	- Behavioral Patterns
  		- Chain of Responsibility
  		- Command
  		- Interpreter
  		- Iterator
  		- Mediator
  		- Memento
  		- NullObject
  		- EmptyArray vs. Null
  		- Observer
  		- State
  		- Strategy
  		- Template Method
  		- Visitor
		- Result/Either Type
 	- Threading Patterns
		- Foundational
			- Producer-Consumer
			- Futures, Promises, Async/Await
			- Reader-Writer Lock
			- Barrier
			- Double Checked Locking
			- AtomicUpdates
	- Data Patterns
	 	- All Dates should be in YYYY-MM-DD format
		- Multi-database Connections for Hot/RealTime/ACID writes, Hot/RealTime/ACID reads, warm-write, warm-read, cold-read, frozen-read, analytics-read, shared-temp (processing, sorting, scratch space, cahced, no backups, no high availability), exclusive-temp (not shared, working/appTempDB, replicated close to running code)
		- Integrity and Management
			- TransactionID
			- Upsert
			- primaryKey + safe & canonical + tainted (use prepared statements) as user entered text entry - fast lookups but proper display
			- Normalization Levels (1NF, 2NF, 3NF, etc...)
			- Timestamps (createTime, updateTime)
			- Locking Types (optimistic, etc..)
			- Unit Recording
			- Currency Handling (store in pennies, etc...)
			- Two Phase Commit (2PC)
			- The Saga Pattern
			- Qurom Updates
		- Data Secrecy
			- hashing
			- Partially/Fully Homomorphic Encryption (PHE/FHE)
			- DataMasking
			- Tokenization
			- Encryption at Rest and at Transit
		- Data Relationship
			- One-to-Many
			- Many-to-One
			- Many-to-Many
			- Split Table with Foreign Key
			- Table to Enum
			- Enum to Lookup Table
			- Star Schema
			- Archive Table
			- Cache Table
		- Db Operations
			- make backup
			- permisson/access investigation
			- performance investigation
			- add user / drop user / rename user
			- add group / drop group / rename group
			- add permission / drop permission / rename permission
		- Table Operations
			- createTable
			- renameTable - avoiding downtime, or informationloss
			- dropTable
			- setTableRemarks
			- mergeColumns
		- Column Operations
			- addColumn
			- renameColumn - avoiding downtime, or info loss
			- dropColumn
			- modifyDataType - avoiding losing info
		- Constraint Management
			- addPrimaryKey
			- dropPrimaryKey
			- addForeignKeyConstraint
			- dropForeignKeyConstraint
			- dropAllForeignKeyConstraint
			- addUniqueConstraint
			- dropUniqueConstraint
			- addNotNullConstraint
			- dropNotNullConstraint
			- addDefaultValue
			- dropDefaultValue
			- addCheckConstraint
			- dropCheckConstraint
			- enableCheckConstraint
			- disableCheckConstraint
		- Index And View Operations
			- createIndex
			- updateIndex
			- dropIndex
			- createView
			- renameView
			- dropView
		- Data Manipulation
			- insert
			- update
			- upsert
			- delete
			- loadData
			- loadUpdateData
			- addLookupTable
		- Stored Logic Sequences
			- createSequence
			- alterSequence
			- renameSequence
			- dropSequence
			- createProcedure
			- dropProcedure
			- createFunction
			- dropFunction
			- createPackage / createPackageBody
			- dropPackage / dropPackageBody
			- createTrigger
			- dropTrigger
			- enableTrigger / disableTrigger
			- renameTrigger
			- createSynonym / dropSynonym
		- Advanced and Misc Changes
			- sql prepared stmt
			- sqlFile
			- customChange
			- executeCommand
			- stop
			- tagDatabase
			- output
		- Complex setup
			- tags
			- rdbms-hierarchacl tags
			- rdbms-graph
 	- **Concept**: Applying transformations to data for security and privacy.
		- `minimize(data)`: To remove all but the essential fields.
		- `redact(data, fieldsToRedact)`: To replace sensitive values with a placeholder.
		- `tokenize(data, field)`: To replace a value with a token.
		- `hash(data)`: For one-way data scrambling.
		- `encrypt(data)`: For two-way data protection.
		- `mask(data, field)`: To partially hide a value (e.g., `***-**-1234`).
		- `compileTimeError`
		- `debugTimeAssertion` - Throw an exception debug
		- `runTimeAssertion` - Throw an exception during runtime
	- Log
		- debug,info,warn,error,critical
	- Alerting
	- Telemetry
		- guage, cumulative, scale, categorical, ordinal, etc...
	- localization
		- new string, update string, delete string, for all country/lang codes - String - datetime to user - number to user - currency to user
	- Docs
		- create/update runbook
		- create/update root-cause-analysis
		- create/update incident
		- create/update business docs (BRD)
		- create/update product docs (personas, PRD, Use Cases)
		- Prioritization procedure
			1. Security
				a. Incidents
				b. Immediate High Risks
			2. Unplanned Outage / Reduction in Service aka Tech Debt Due: Urgent & Important
			3. Current Clients: Keep
			4. Guaranteed Profit Opportunitites
			4. Unblock Internal Teams
			4. Current Clients: Upsell
			4. Acquire Clients
				a. Recurring Revenue
				a. Flat Revenue
			8. High EBITDA Tech Debt
			8. Planned R&D
			8. Non Outage / Reduction Tech Debt: Urgent & Important
			10. Speculative R&D
			8. Tech Debt: Not Urgent & Important
			8. Tech Debt: Urgent & Not Important
			8. Tech Debt: Not Urgent & Not Important
		- Incident Handling
			1. Mitigation - Stop the bleed, reference playbooks, inform stakeholders, update public & private status dashboard
			1. Remediation - Short term workaround
			1. Analysis - Understand What happened
			1. Post Mortem - Tickets for short term, long term, report, present to stakeholders, communicate to users
			1. Fix Prioritization
			1. Short term fixes
			1. Long term fixes



## Cloud Tagging

This is one action with the information to tag cloud resources
	- Cloud
		- tagging
			- tech
				- purpose: reporting, core, ingest, export, transient, custom, adhoc
				- App
				- Service
				- Version
				- Environment
				- SLA expected
				- Deploying individual
				- Deploying department
				- pattern template used in consturction
			- Biz
				- requesting Department amanger
				- requesting individual
				- requesting department
				- Product
			- Governance
				- PII Level
				- Compliance REquired [SOC, PCI, etc...]
				- Security Classification
				- Retiredate
				- Cost Center
				- Tenancy
			- Lineage
				- Upstreams
				- Downstreams

## Architecture Patterns
Here’s a comprehensive catalog of foundational software development principles—structured for clarity and reproducibility. These principles guide maintainability, modularity, and override-aware architecture across systems:

---

### 🧠 Core Design Principles

| Principle | Summary | Purpose |
|----------|---------|--------|
| **DRY** (Don't Repeat Yourself) | Avoid code duplication | Reduces maintenance overhead and inconsistency |
| **KISS** (Keep It Simple, Stupid) | Favor simplicity over cleverness | Enhances readability and reduces bugs |
| **YAGNI** (You Aren’t Gonna Need It) | Don’t build features until necessary | Prevents overengineering |
| **SOLID** | Five OOP principles for scalable design | Promotes modular, testable, and maintainable code |

---

### 🔧 SOLID Breakdown

| Principle | Description |
|----------|-------------|
| **S** - Single Responsibility | Each module/class should have one reason to change |
| **O** - Open/Closed | Software entities should be open for extension, closed for modification |
| **L** - Liskov Substitution | Subtypes must be substitutable for their base types |
| **I** - Interface Segregation | Prefer many specific interfaces over one general-purpose interface |
| **D** - Dependency Inversion | Depend on abstractions, not concretions |

---

### 🔗 Coupling & Cohesion

| Concept | Description |
|--------|-------------|
| **Loosely Coupled** | Modules interact via well-defined interfaces, minimizing dependencies |
| **Avoid: Tightly Coupled** | Modules are interdependent, making changes risky and harder to isolate |
| **High Cohesion** | Related functionality is grouped together, improving clarity and reuse |

---

### 🧩 Architectural & Behavioral Principles

| Principle | Description |
|----------|-------------|
| **Separation of Concerns** | Divide responsibilities across layers/modules |
| **Composition Over Inheritance** | Favor object composition to promote flexibility |
| **Law of Demeter** | “Talk only to your immediate friends” — limit knowledge of other modules |
| **Fail Fast** | Detect and report errors early in execution |
| **Immutability** | Prefer immutable data structures to reduce side effects |
| **Convention Over Configuration** | Use sensible defaults to reduce setup complexity |

---

### 🧪 Testability & Maintainability

| Principle | Description |
|----------|-------------|
| **Test-Driven Development (TDD)** | Write tests before implementation |
| **Behavior-Driven Development (BDD)** | Focus on expected behavior via human-readable specs |
| **Clean Code** | Prioritize readability, naming, and structure |
| **Refactor Often** | Continuously improve code without changing behavior |

---
