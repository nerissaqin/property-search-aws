Sam cli is used to do deployment for api gateway and lambda (backend for client website and admin website). For our current useage, it reads data and write data to dymanodb tables. Decoupling frontend and backend.

## steps
- test in local: `sam build; sam local start api`
- deployment: `sam build; sam deploy`