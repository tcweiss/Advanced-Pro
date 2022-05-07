# Clone branch.
library(usethis)
create_from_github("tcweiss/Advanced-Pro",
                   fork = TRUE,
                   destdir = "/Users/duerr/OneDrive/Documents/Ausbildung/HSG/FS22/Programming/Advanced-Pro",
                   protocol = "https")

# In new project, create a new branch with a sensitive name.
library(usethis)
pr_init(branch = "samuel")

# Run this to activate the branch.
pr_push()


# Finally, restart R. You should have a Git tab in Rstudio.
