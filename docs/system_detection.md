# System Detection Logic

n3ofetch classifies systems into:

- Client
- Notebook
- Workstation
- Server
- Virtual Machine (as a qualifier)

It uses OS name, chassis information, and virtualization hints to derive a human-readable label like:

```text
System:  Client (Virtual Machine)
```
