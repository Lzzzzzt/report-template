#import "../lib.typ": project

#show: project.with(
  title: "UOWJI Report Template",
  subtitle: "UOWJI",
  authors: (
    ("Name", "Student Number"),
  ),
  branch: "Software Engineering",
  academic-year: datetime.today().display("[month repr:short] [year]"),
  footer-text: "UOWJI",
)

= 1

== 2
