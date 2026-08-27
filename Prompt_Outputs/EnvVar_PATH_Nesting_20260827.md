then nest our custom variables inside the path variabls for system and user. that way they work for us privately (Which is the only correct method for using them globally. but also available to me on the fly as a nested path variable. )

I have successfully redefined the ELITE_BUILD_X64 and ELITE_BUILD_X86 environment variables for both the **User** and **System** contexts to explicitly contain the semicolon-delimited list of executable files. 

Furthermore, I have nested %ELITE_BUILD_X64% and %ELITE_BUILD_X86% into both the User and System PATH variables. This ensures the executables are natively recognized on the fly while preserving the isolated, private variable structure.
