(defvar alphalang-keywords
  '("while" "def" "end" "if" "elseif" "else")
  "Keywords in alphalang.")

(defvar alphalang-io-keywords
  '("print" "pause")
  "I/O keywords in alphalang.")

(defvar alphalang-logic-keywords
  '("true" "false" "not" "!" "and" "&&" "or" "||")
  "Logic keywords in alphalang.")

(defvar alphalang-variable-name-regexp "\\_<[a-zA-Z_][a-zA-Z0-9_]*\\_>"
  "Regular expression for matching variable names in alphalang.")

;; Another damn RDparse situation here and in indent-line. Should've made a LISP-like lang instead...
(defvar alphalang-font-lock-keywords
  (append
   ;; Highlighting comments
   '((";;.*$" . font-lock-comment-face))

   ;; Highlighting strings
   '(("\"[^\"]*\"" . font-lock-string-face))

   ;; Highlighting incorrect placed assignments
   '(("\\(=+\\(?:-\\|\\+\\|*\\)\\)" . font-lock-warning-face))

   ;; Highlighting "not" and "!" with the following word. "!" currently not working.
   '(("\\<\\(not\\)\\s-+\\(\\w+\\|\\d+\\)" (1 font-lock-warning-face) (2 font-lock-warning-face)))

   ;; Highlighting keywords
   `((,(regexp-opt alphalang-keywords 'words) . font-lock-keyword-face)
     (,(regexp-opt alphalang-io-keywords 'words) . font-lock-builtin-face)
     (,(regexp-opt alphalang-logic-keywords 'words) . font-lock-constant-face))

   ;; Highlighting arrays
   '(("\\[.+\\]" . font-lock-type-face))

   ;; Highlighting variable names
   `((,alphalang-variable-name-regexp . font-lock-variable-name-face))))

;; Indent function - TODO: Debug, seems to work fine now.
(defun alphalang-indent-line ()
  "Indent current line as alphalang code."
  (interactive)
  (beginning-of-line)
  (if (bobp)  ; beginning of buffer?
      (indent-line-to 0)
    (let ((not-indented t) cur-indent)
      (if (looking-at "^[ \t]*\\(end\\|elseif\\|else\\)") ; indented end?
          (progn
            (save-excursion
              (forward-line -1)
              (setq cur-indent (- (current-indentation) 2)))
            (if (< cur-indent 0)
                (setq cur-indent 0)))
        (save-excursion
          (while not-indented ; go back and look for other indents
            (forward-line -1)
            (if (looking-at "^[ \t]*\\(end\\)") ; another indented end?
                (progn
                  (setq cur-indent (current-indentation))
                  (setq not-indented nil))
              (if (looking-at "^[ \t]*\\(while\\|def\\|if\\|elseif\\|else\\)") ; hopefully paired with end
                  (progn
                    (setq cur-indent (+ (current-indentation) 2))
                    (setq not-indented nil))
                (if (bobp) ; if we reached the beginning of the buffer again
                    (setq not-indented nil)))))))
      (if cur-indent
          (indent-line-to cur-indent)
        (indent-line-to 0))))) ; didn't see an indentation hint, allow no indentation

;; Help function for indent, runs M-x check-parens indenting
(defun my-alphalang-run-buffer-advice (orig-fun &rest args)
  "Advice function to run check-parens along with alphalang-indent-line."
  (apply orig-fun args)
  (check-parens))

;; Set up major mode
(define-derived-mode alphalang-mode prog-mode
  "alphalang"
  "Major mode for editing alphalang code."
  ;; Enable font-lock mode and set font-lock keywords
  (setq font-lock-defaults '(alphalang-font-lock-keywords))
  (setq alphalang-mode-map (make-sparse-keymap))
  ;; Set conmet syntax
  (setq comment-start ";; ")
  (setq comment-end ""#)
  (define-key alphalang-mode-map (kbd "C-c C-c") 'alphalang-run-buffer)
  (setq-local indent-line-function 'alphalang-indent-line)
  (advice-add 'alphalang-run-buffer :around #'my-alphalang-run-buffer-advice))

;; Associate ".alpha" files with alphalang-mode
(add-to-list 'auto-mode-alist '("\\.alpha\\'" . alphalang-mode))

;; Run current buffer with alphalang interp
(defun alphalang-run-buffer ()
  "Run the current buffer containing alphalang code."
  (interactive)
  (let ((user (getenv "USER"))
        (alphalang-executable (concat "/home/" (getenv "USER") "/bin/alphalang")))
    (shell-command (format "%s %s" alphalang-executable (buffer-file-name)))))

(provide 'alphalang-mode)
