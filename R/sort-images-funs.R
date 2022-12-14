#' Generate and sort keywords function
#'
#' @param y A tibble
#'
#' @return Keywords
#' @export
#'
#' @examples
#' dalle_keywords()
dalle_keywords <- function(y) {

        # find most common words
        freq <-
                y %>%  tidytext::unnest_tokens(word, x, to_lower = TRUE) %>% dplyr::count(word, sort = TRUE)

        # remove stopwords based on stopwords-iso
        filtered <-
                freq %>% dplyr::filter(!(
                        word %in% stopwords::stopwords(source = "stopwords-iso")
                ))

        filtered <- filtered %>% dplyr::filter(!grepl("[1-4]", word))
}

#' dalle_import function
#'
#' Create a keyword list based on image file names in a directory
#' @param imgpath A full path to your image file directory
#' @keywords image
#' @return Character vector of keywords
#' @export
#'
#' @examples
#' dalle_import(imgpath = "~/Pictures/DallE")
dalle_import <- function(imgpath) {
        dalle_images <-
                list.files(path = imgpath, pattern = ".png", full.names = FALSE)

        dalle_images_t <- tibble::tibble(x = dalle_images)

        # gsub numbers 1-4 and .png
        dalle_images_t$x <-
                gsub(" - [0-9]", "", dalle_images_t$x)

        dalle_images_t$x <-
                gsub(" - variation[0-9]", "", dalle_images_t$x)

        dalle_images_t$x <-
                gsub(" using ", " ",
                gsub(" wearing ", " ",
                gsub(" style ", " ",
                gsub(" lots ", " ",
                          dalle_images_t$x))))

        dalle_images_t$x <-
                gsub(".png", "", dalle_images_t$x)

        dalle_images_t$x <-
                gsub("playstation 1", "playstationone", dalle_images_t$x)

        keys <- dalle_keywords(y = dalle_images_t)
}

#' Sort images function
#'
#' This uses a keyword list generated by dalle_import and sorts images into folders.
#' @param keywords Character vector of keywords
#' @param imgpath A full path to your image file directory
#'
#' @return Sorts images
#' @export
#'
#' @examples
#' sort_images(keywords = my-key-words, imgpath = "~/Pictures/DallE")
sort_images <- function(keywords, imgpath) {
        search_images_remove <- NULL
        dalle_images_1 <-
                list.files(path = imgpath,
                           pattern = ".png",
                           full.names = TRUE)
        search_images_master <- dalle_images_1
        for (key_word in keywords[["word"]]) {

                # look through the list of files for matches
                search_images <- grep(key_word, search_images_master, value = TRUE)

                # if there is a match, create a folder (if doesn't already exist)
                # then move the matching images into the just created / existing folder

                if (length(search_images) == 0) {
                        cat("no matches...", key_word, fill = TRUE)
                } else {

                        cat("there was a keyword match...", key_word, fill = TRUE)

                        new_dir <- file.path(imgpath, key_word)

                        if (dir.exists(new_dir)) {
                        cat("directory already exists, copying files...", fill = TRUE)
                        } else {
                                dir.create(new_dir)
                                cat("created a new directory...", fill = TRUE)
                        }

                        # list of images to remove from the master list
                        search_images_remove <- search_images
                        search_images_remove <- paste(search_images_remove, collapse = '|')

                        search_images_master <-
                                grep(pattern = search_images_remove,
                                     x = search_images_master,
                                     value = TRUE,
                                     invert = TRUE)
                        # move
                        for (image in search_images) {
                                file.copy(image, new_dir)
                                search_images <-
                                        search_images %>%
                                        stringr::str_subset(pattern = image, negate = TRUE)
                        }
                }
        }
}
