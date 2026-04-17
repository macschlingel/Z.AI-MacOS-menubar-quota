import re

with open("ZaiSubscriptionWidget/Views/MenuBarView.swift", "r") as f:
    content = f.read()

# We need to extract the costWindowSection from HEAD, and the quotaBar from the feature branch.
# The structure is:
# <<<<<<< HEAD
#     private var quotaSection: some View { ... }
#     private var costWindowSection: some View { ... }
# =======
#     private func quotaBar(...) -> some View { ... }
# >>>>>>> feature/quota-reset-time

match = re.search(r'<<<<<<< HEAD\n.*?    private var costWindowSection(.*?)\n=======\n(.*?)\n>>>>>>> feature/quota-reset-time', content, re.DOTALL)

if match:
    cost_window = '    private var costWindowSection' + match.group(1)
    quota_bar = match.group(2)
    
    new_content = content.replace(match.group(0), f"{cost_window}\n\n{quota_bar}")
    with open("ZaiSubscriptionWidget/Views/MenuBarView.swift", "w") as f:
        f.write(new_content)
    print("Conflict resolved successfully.")
else:
    print("Conflict pattern not found.")
