library(testthat)
library(here)

# Source business logic relative to your project root safely
source(here("business_logic", "business_logic.R"))

# Read your CSV relative to project root
csv_path <- here("tests", "testthat", "Pass1.csv")
test_csv <- read.csv(csv_path, stringsAsFactors = FALSE)

test_that("validate_csv rejects invalid CSVs and returns error strings", {
  expect_equal(validate_csv(NULL), "Invalid CSV structure: must have exactly 6 columns.")

  df_wrong_cols <- data.frame(a=1:3, b=4:6)
  expect_equal(validate_csv(df_wrong_cols), "Invalid CSV structure: must have exactly 6 columns.")

  df_missing_site <- data.frame(date=as.character(Sys.Date() + 1:3), site=NA, type="A", x=1, y=2, z=3)
  df_missing_site$site <- NULL
  expect_equal(validate_csv(df_missing_site), "Missing required column: site")

  df_bad_date <- data.frame(date=c("31-02-2022"), site="s1", type="t1", a=1, b=2, c=3)
  expect_equal(validate_csv(df_bad_date), "Invalid date format in 'date' column. Expected formats: DD-MM-YYYY")
})

test_that("validate_csv accepts and processes valid data frames", {
  result <- validate_csv(test_csv)
  expect_true(is.data.frame(result))
  expect_equal(ncol(result), 6)
  expect_true("kg" %in% colnames(result))
  expect_true(all(class(result$date) == "Date"))
})

test_that("calc_statistics returns stats or errors correctly", {
  df <- validate_csv(test_csv)
  stats <- calc_statistics(df)
  expect_true(is.data.frame(stats))
  expect_equal(stats$Metric, c("Total Cost", "Average Cost", "Total Emissions"))
  expect_equal(stats$Value[stats$Metric == "Total Cost"], round(sum(test_csv[,5], na.rm = TRUE), 2))
  expect_equal(stats$Value[stats$Metric == "Average Cost"], round(mean(test_csv[,5], na.rm = TRUE), 2))
  expect_equal(stats$Value[stats$Metric == "Total Emissions"], round(sum(test_csv[,6], na.rm = TRUE), 2))

  df_invalid <- "This is not a data frame"
  out <- calc_statistics(df_invalid)
  expect_true(is.character(out))
})
