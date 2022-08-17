# TODO

## High Priority

### Psych Engine
- Update to 0.6.2

### Safe Script Option
- Fix vulnerability with commands
    **1.** Have a list of blacklisted commands and flag the script as malicious if it uses a script that is blacklisted
- Fix vulnerability with files
    **1.** Limit only the file system to itself
    **2.** Have a size limit for what file it recently wrote
- Fix vulnerability with URLs
    **1.** Check for potential unsafe scripts containing "untrusted" links, if the script contains a link, do two things:
    
    - Compare the link to a list that is considered safe, if the link is unsafe, attempt to do no. 2 on the list

    - If the script is attempting to redirect the user to that link, check if the link is considered safe with a list, otherwise, flag the script as malicious
 ⠀

    **2.** Check if the script is attempting to use a GET request from the link, then have a check if the link contains an IPv4, IPv6, any sensitive information, if it does, then flag the script as malicious
    ⠀
- Flagging a Script
    * Flagging a script means to stop the script and do actions depending on the user's options