# IdleScheduler
Started as a script to mine while system is idle. Has been expanded to be a multi function idle handler. It must be run as an administrator to function proper.

Windows task scheduler will not consider a system idle if there is any resource consumption such as CPU, GPU, etc. This script was written as a way around that limitation as I have services running tasks 24/7 in a server role.

Idle states are detected as follows:
- User session is currently locked
- User has provided no physical input for up to 600 seconds

It will run and handle any Windows Scheduler tasks in the main branch that have idle condition configurations.
- "Start task only if the computer is idle" is handled and will wait this long before triggering the task
- "Wait for idle for" is currently ignored and not used
- "Stop if the computer ceases to be idle" is handled and will stop the selected tasks if enabled
- "Restart if the idle state resumes" is currently ignored and not used

It will run a batch script immediately after user idle is confirmed based on the detection methods above.
Subsequently a batch script will run after the user is no longer idle.
