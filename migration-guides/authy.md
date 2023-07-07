# Migrating from Authy
A guide written by Green, an ente.io lover

---

Migrating from Authy can be tiring, as there is you cannot export your 2FA codes through the app, meaning that you would have to reconfigure 2FA for all of your accounts for your new 2FA authenticator. But do not fear, as there is a much simpler way to migrate from Authy to ente Authenticator.

A user on GitHub has written a guide to export our data from Authy (morpheus on Discord found this and showed it to us), so we are going to be using that for the migration.

## Exporting from Authy
To export your data, please follow [this guide](https://gist.github.com/gboudreau/94bb0c11a6209c82418d01a59d958c93). This will create a new JSON file with all your Authy TOTP data in it. **Do not share this file with anyone!**

## Converting the export for ente Authenticator
So now that you have the JSON file, does that mean it can be imported into ente Authenticator? Nope.

This is because the code in the guide exports your Authy data for Bitwarden, not ente Authenticator. If you have opened the JSON file, you might have noticed that the file created is not in a format that ente Authenticator asks for:

<img width="454" alt="ente Authenticator Screenshot" src="https://github.com/gweeeen/auth/assets/41323182/30566a69-cfa0-4de0-9f0d-95967d4c5cad">

So, this means that even if you try to import this file, nothing will happen. But don't worry, I've written a program in Python that converts the JSON file into a TXT file that ente Authenticator can use!

You can download my program [here](https://github.com/gweeeen/ducky/blob/main/duckys_other_stuff/authy_to_ente.py). Or if you **really like making life hard**, then you can make a new Python file and copy this code to it:

```py
import json
import os

totp = []

accounts = json.load(open('authy-to-bitwarden-export.json','r',encoding='utf-8'))

for account in accounts['items']:
    totp.append(account['login']['totp']+'\n')

writer = open('auth_codes.txt','w+',encoding='utf-8')
writer.writelines(totp)
writer.close()

print('Saved to ' + os.getcwd() + '/auth_codes.txt')
```

To convert the file with this program, you will need to install [Python](https://www.python.org/downloads/) on your computer.

Before you run the program, make sure that both the Python program and the JSON file are in the same directory, otherwise this will not work!

To run the Python program, open it in IDLE and press F5, or open your terminal and type `python3 authy_to_ente.py` or `py -3 authy_to_ente.py`, depending on which OS you have. Once you run it, a new TXT file called `auth_codes.txt` will be generated. You can now import your data to ente Authenticator!

## Importing to ente Authenticator
Now that we have the TXT file, let's import it. This should be the easiest part of the entire migration process.

1. Copy the TXT file to one of your devices with ente Authenticator.
2. Log in to your account (if you haven't already).
3. Open the navigation menu (hamburger button on the top left), then press "Data", then press "Import codes".
4. Select the TXT file that was made earlier.

And that's it! You have now successfully migrated from Authy to ente Authenticator.
