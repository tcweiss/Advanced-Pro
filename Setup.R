
##############
###  SETUP  ##
##############

# 1. If something seems messed up, delete the project directory on your laptop.
# Next, delete the repo on your own Github account. Just set up the project from scratch again using this code:

library(usethis)
create_from_github("tcweiss/Advanced-Pro",
                   fork = TRUE,
<<<<<<< HEAD
                   destdir = "/Users/duerr/OneDrive/Documents/Ausbildung/HSG/FS22/Programming/Advanced-Pro",
=======
                   destdir = "",
>>>>>>> cf151ec6294138db408678c5955d039d9bf9bafe
                   protocol = "https")

# 2. Once a window opens with the new project, run this:
library(usethis)
<<<<<<< HEAD
pr_init(branch = "samuel")
=======
pr_init(branch = "")
pr_push()

# Click on the "Git" tab and make sure that you have selected the branch you
# created above. DO NOT CHOOSE "MAIN".
>>>>>>> cf151ec6294138db408678c5955d039d9bf9bafe


#################
###  WORKLFOW  ##
#################

# Whenever you open the project, first pull from "main":
pr_pull_upstream()

# Once you made some changes, click on the "Git" tab and tick everything. Click
# on "Commit" and enter a message. Click "Push" to send it to your own branch on
# Github. This is a different version than "main". If you made a few changes and
# think that the code is error-free, you will want to merge the changes from
# your own Github branch to "main". To do this, run:
pr_push()



