#let IMAGE_BOX_MAX_WIDTH = 200pt
#let IMAGE_BOX_MAX_HEIGHT = 50pt

#let supported-langs = ("en", "fr", "ar")

#let full-page-chapter = state("full-page-chapter", false)

#let project(
  title: "",
  subtitle: none,
  header: none,
  school-logo: none,
  company-logo: none,
  authors: (),
  mentors: (),
  jury: (),
  branch: none,
  academic-year: none,
  french: false,
  lang: none,
  footer-text: "ENSIAS",
  features: (),
  heading-numbering: "1.1",
  accent-color: rgb("#ff4136"),
  defense-date: none,
  show-table-of-figures: false,
  show-table-of-tables: false,
  body,
) = {
  // 提取第一列：既能处理一维 authors，也能处理二维 authors
  let get-authors(authors) = {
    // 如果根本不是数组（比如传进来是单个值），先封装成一维数组
    if type(authors) != array {
      (authors,)
    } else if authors.len() == 0 {
      // 空数组，直接返回空
      ()
    } else {
      // 看第一个元素的类型，决定是一维还是二维
      let first = authors.at(0)

      // 二维情况：比如 (("A", 1), ("B", 2))
      if type(first) == array {
        authors.map(row => row.at(0))
      } // 一维情况：比如 ("A", "B", "C")
      else {
        authors
      }
    }
  }


  if lang == none {
    // Fallback by the time the param gets removed after deprecation
    if french {
      lang = "fr"
    } else {
      lang = "en"
    }
  }

  if not supported-langs.contains(lang) {
    panic("Unsupported `lang` value. Supported languages: " + supported-langs.join(","))
  }

  let dict = json("resources/i18n/" + lang + ".json")

  // Set the document's basic properties.
  let authors-list = get-authors(authors)
  set document(author: authors-list, title: title)

  set page(header: context {
    let headings = query(heading.where(level: 1).before(here()))
    let current-page-headings = query(heading.where(level: 1).after(here())).filter(h => (
      h.location().page() == here().page()
    ))
    if headings == () {
      []
    } else {
      let current-chapter = headings.last()
      if current-chapter.level == 1 and current-chapter.numbering != none {
        let in-page-heading = if current-page-headings.len() > 0 { current-page-headings.first() } else { none }
        if in-page-heading == none or in-page-heading.level != 1 or in-page-heading.numbering == none {
          let count = counter(heading).at(current-chapter.location()).at(0)
          align(end)[
            #text(accent-color, weight: "bold")[
              #dict.chapter #count:
            ]
            #current-chapter.body
            #line(length: 100%)
          ]
        }
      }
    }
  }) if features.contains("header-chapter-name")

  set page(
    numbering: "1",
    number-align: center,
    footer: context {
      // Omit page number on the first page
      let page-number = counter(page).get().at(0)

      if page-number >= 1 and not full-page-chapter.get() {
        line(length: 100%, stroke: 0.5pt)
        v(-2pt)
        text(size: 12pt, weight: "regular")[
          #footer-text
          #h(1fr)
          #page-number
          #h(1fr)
          #academic-year
        ]
      }
      full-page-chapter.update(false)
    },
  )

  set text(lang: lang, size: 11pt)
  set heading(numbering: heading-numbering)

  show heading: it => {
    if it.level == 1 and it.numbering != none {
      if features.contains("full-page-chapter-title") {
        pagebreak()
        full-page-chapter.update(true)

        v(1fr)
        [
          #text(weight: "regular", size: 30pt)[
            #dict.chapter #counter(heading).display()
          ]
          #linebreak()
          #text(weight: "bold", size: 36pt)[
            #it.body
          ]
          #line(start: (0%, -1%), end: (15%, -1%), stroke: 2pt + accent-color)
        ]
        v(1fr)

        pagebreak()
      } else {
        pagebreak()
        full-page-chapter.update(false)
        v(40pt)
        text(size: 1em)[#dict.chapter #counter(heading).display()]
        linebreak()
        text(size: 1.2em)[#smallcaps(it.body)]
        v(2em)
      }
    } else {
      full-page-chapter.update(false)
      v(5pt)
      [#it]
      v(12pt)
    }
  }

  counter(page).update(0)

  if header != none {
    h(1fr)
    box(width: 60%)[
      #align(center)[
        #text(weight: "medium")[
          #header
        ]
      ]
    ]
    h(1fr)
  }

  block[
    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(start + horizon)[
        #if school-logo == none {
          image("images/image.png")
        } else {
          school-logo
        }
      ]
    ]
    #h(1fr)
    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(end + horizon)[
        #company-logo
      ]
    ]
  ]

  // Title box
  align(center + horizon)[
    #if subtitle != none {
      text(size: 14pt, tracking: 2pt)[
        #smallcaps[
          #subtitle
        ]
      ]
    }
    #line(length: 100%, stroke: 0.5pt)
    #text(size: 20pt, weight: "bold")[#title]
    #line(length: 100%, stroke: 0.5pt)
  ]

  // Credits
  box()
  h(1fr)
  grid(
    columns: (auto, 1fr, auto),
    [
      #{
        let data = if type(authors) == array { authors } else { (authors,) }
        set table(stroke: none, align: start, inset: (x: 0pt, y: 4pt), column-gutter: 2em)

        if data.len() == 0 {
          table(columns: 1)
        } else {
          let first = data.at(0)

          if type(first) == array {
            let cols = first.len()

            text(weight: "bold")[
              #if authors.len() > 1 {
                dict.author_plural
              } else {
                dict.author
              }
              #linebreak()
            ]
            v(-1em)
            table(
              // 列数取第一行长度
              columns: cols,
              ..data.flatten().map(it => [#it]),
            )
          } // 情况二：一维 authors，例如 ("A", "B", "C")
          else {
            table(
              columns: 1,
              // 一维时，每个元素就是一行的一格
              ..data,
            )
          }
        }
      }
    ],
    [
      // Mentor
      #if mentors != none and mentors.len() > 0 {
        align(end)[
          #text(weight: "bold")[
            #if mentors.len() > 1 {
              dict.mentor_plural
            } else {
              dict.mentor
            }
            #linebreak()
          ]
          #for mentor in mentors {
            mentor
            linebreak()
          }
        ]
      }
      // Jury
      #if defense-date == none and jury != none and jury.len() > 0 {
        align(end)[
          *#dict.jury* #linebreak()
          #for prof in jury {
            [#prof #linebreak()]
          }
        ]
      }
    ],
  )

  align(center + bottom)[
    #if defense-date != none and jury != none and jury.len() > 0 {
      [*#dict.defended_on_pre_date #defense-date #dict.defended_on_post_date:*]
      // Jury
      align(center)[
        #for prof in jury {
          [#prof #linebreak()]
        }
      ]
      v(60pt)
    }
    #if branch != none {
      branch
      linebreak()
    }
    #if academic-year != none {
      [#dict.academic_year: #academic-year]
    }
  ]

  pagebreak()

  // Table of contents.
  outline(depth: 3, indent: auto)

  if show-table-of-figures {
    pagebreak()

    // Table of figures.
    outline(
      title: dict.figures_table,
      target: figure.where(kind: image),
    )
  }

  if show-table-of-tables {
    pagebreak()

    outline(
      title: dict.tables_table,
      target: figure.where(kind: table),
    )

    pagebreak()
  }

  counter(page).update(0)

  // Main body.
  body
}
