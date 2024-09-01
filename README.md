# NXRe
Auto Rename NSP/XCI on Windows

**This software require that you add in same folder : ``prod.keys`` and ``title.keys``**

---

## Step-by-Step Guide to Setting Up Your Files and Adding to Windows PATH

To ensure proper functionality of the software, you need to place all related files in a designated folder and add that folder to the Windows PATH environment variable. This will allow you to run the software from any command prompt without having to specify the full path.

### 1. Place Your Files in the Designated Folder

1. **Create a Folder (if not already created):**
   - Navigate to `C:\Program Files\` on your computer.
   - Create a new folder named `NXRe` if it doesn't already exist.

2. **Move Files to the Folder:**
   - Copy all the necessary files for the software.
   - Paste them into `C:\Program Files\NXRe`.

### 2. Add the Folder to the Windows PATH

1. **Open Environment Variables:**
   - Right-click on the **Start** menu and select **System**.
   - Click on **Advanced system settings** on the left.
   - In the System Properties window, click on the **Environment Variables** button.

2. **Edit the PATH Variable:**
   - In the **Environment Variables** window, find the **Path** variable under the "System variables" section and select it.
   - Click on **Edit...**.

3. **Add the New Path:**
   - In the **Edit Environment Variable** window, click on **New**.
   - Type in the path to the folder where your files are located, for example: `C:\Program Files\NXRe`.
   - Click **OK** to close each window.

4. **Confirm Changes:**
   - Open a new Command Prompt window (important: a new window to apply changes).
   - Type `echo %PATH%` and press **Enter** to verify that your new path has been added.

### 3. Verify Installation

To ensure everything is set up correctly:

- Open a Command Prompt window.
- Type the command to run your software (for example, `nxr C:/Path/of/your/nsp`).
- If the software runs without any errors, the setup is complete.

### Notes

- **Administrator Permissions**: You might need administrative privileges to move files to `C:\Program Files` and to modify the PATH variable.

By following these steps, this software should now be ready to run from any location in the Command Prompt.
---

Thanks [Garoxas](https://github.com/garoxas/) for [NX Game Info](https://github.com/garoxas/NX_Game_Info)
