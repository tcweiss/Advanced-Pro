# Clone branch.
library(usethis)
create_from_github("tcweiss/Advanced-Pro",
                   fork = FALSE,
                   destdir = "/Users/thomasweiss/Desktop/Uni/Advanced Programming/Code",
                   protocol = "https")

# In new project, create a new branch with a sensitive name.
library(usethis)
pr_init(branch = "thomas")

# Run this to activate the branch.
pr_push()


# Finally, restart R. You should have a Git tab in Rstudio.


