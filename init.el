;; -*- lexical-binding: t; -*-

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

(defun efs/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                     (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'efs/display-startup-time)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(setf
 straight-vc-git-default-protocol 'https
 straight-use-package-by-default t
 use-package-verbose t
 use-package-always-demand t)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("org" . "https://orgmode.org/elpa/")
        ("elpa" . "https://elpa.gnu.org/packages/")))

(use-package emacs
  :config
  (load-theme 'modus-vivendi)
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
		  (replace-regexp-in-string
		   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
		   crm-separator)
		  (car args))
	  (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  (setq inhibit-startup-message t)

  (scroll-bar-mode -1)			; Disable visible scrollbar
  (tool-bar-mode -1)			; Disable the toolbar
  (tooltip-mode -1)			; Disable tooltips
  (set-fringe-mode 8)
  (menu-bar-mode -1)			; Disable the menu bar
  (setq visible-bell t)
  (blink-cursor-mode -1)
  (column-number-mode)
  ;; (setf display-line-numbers-type 'relative)
  (global-display-line-numbers-mode t)

  ;; Disable line numbers for some modes
  (dolist (mode '(org-mode-hook
                  term-mode-hook
                  shell-mode-hook
                  treemacs-mode-hook
                  eshell-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 0))))

  (global-set-key (kbd "<escape>") 'keyboard-escape-quit)
  (setq use-dialog-box nil)
  (defalias 'yes-or-no-p 'y-or-n-p)
  (setq create-lockfiles nil)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
	'(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  (setq inhibit-startup-message t
	initial-scratch-message "")
;;; Show matching parenthesis
  (show-paren-mode 1)
;;; By default, there’s a small delay before showing a matching parenthesis. Set
;;; it to 0 to deactivate.
  (setq show-paren-delay 0)
  (setq show-paren-when-point-inside-paren t)

  (setq show-paren-style 'parenthesis)
;;; Electric Pairs to auto-complete () [] {} "" etc. It works on regions.

  (electric-pair-mode)
  (setq redisplay-skip-fontification-on-input t
	fast-but-imprecise-scrolling t)
  (global-so-long-mode 1)
  (setq async-shell-command-buffer 'new-buffer)

  (defun path-slug (dir)
    "Returns the initials of `dir`s path,
with the last part appended fully

Example:

(path-slug \"/foo/bar/hello\")
=> \"f/b/hello\" "
    (let* ((path (replace-regexp-in-string "\\." "" dir))
	   (path (split-string path "/" t))
	   (path-s (mapconcat
		    (lambda (it)
		      (cl-subseq it 0 1))
		    (nbutlast (copy-sequence path) 1)
		    "/"))
	   (path-s (concat
		    path-s
		    "/"
		    (car (last path)))))
      path-s))

  (defun mm/put-command-in-async-buff-name (f &rest args)
    (let* ((path-s (path-slug default-directory))
	   (command (car args))
	   (buffname (concat path-s " " command))
	   (shell-command-buffer-name-async
	    (format
	     "*async-shell-command %s*"
	     (string-trim
	      (substring buffname 0 (min (length buffname) 50))))))
      (apply f args)))

  (advice-add 'shell-command :around #'mm/put-command-in-async-buff-name)

  (add-hook 'comint-mode-hook
	    (defun mm/do-hack-dir-locals (&rest _)
	      (hack-dir-local-variables-non-file-buffer)))

  (advice-add #'start-process-shell-command :before #'mm/do-hack-dir-locals)

  (advice-add 'compile :filter-args
	      (defun mm/always-use-comint-for-compile (args) `(,(car args) t)))

  :bind ("<f5>" . modus-themes-toggle))

(use-package mood-line
  :straight (:host github :repo "benjamin-asdf/mood-line")
  :config
  (setf mood-line-show-cursor-point t)
  (mood-line-mode))

(use-package vertico
  :init
  (vertico-mode)
  (setq vertico-scroll-margin 0)
  (setq vertico-count 20)
  (setq vertico-cycle t))

(use-package savehist :init (savehist-mode))

(use-package orderless
  :init
  (setq
   completion-styles '(orderless basic)
   completion-category-defaults nil
   completion-category-overrides '((file (styles partial-completion)))))

(require 'dired)

;; https://github.com/Gavinok/emacs.d
(use-package consult
  :ensure t
  :bind (("C-x b"       . consult-buffer)
         ("C-x C-k C-k" . consult-kmacro)
         ("M-y"         . consult-yank-pop)
         ("M-g g"       . consult-goto-line)
         ("M-g M-g"     . consult-goto-line)
         ("M-g f"       . consult-flymake)
         ("M-g i"       . consult-imenu)
         ("M-s l"       . consult-line)
         ("M-s L"       . consult-line-multi)
         ("M-s u"       . consult-focus-lines)
         ("M-s g"       . consult-grep)
         ("M-s M-g"     . consult-grep)
         ("C-x C-SPC"   . consult-global-mark)
         ("C-x M-:"     . consult-complex-command)
         ("C-c n"       . consult-org-agenda)
         :map dired-mode-map
         ("O" . consult-file-externally)
         :map help-map
         ("a" . consult-apropos)
         :map minibuffer-local-map
         ("M-r" . consult-history))
  :custom
  (completion-in-region-function #'consult-completion-in-region)
  :config
  (recentf-mode t))

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; https://github.com/oantolin/embark
(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)		;; pick some comfortable binding
   ("C-;" . embark-dwim)	;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'
  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package bash-completion
  :init
  (autoload 'bash-completion-dynamic-complete
    "bash-completion"
    "BASH completion hook")
  (add-hook 'shell-dynamic-complete-functions
            #'bash-completion-dynamic-complete)

  :config
  (defun bash-completion-capf-1 (bol)
    (bash-completion-dynamic-complete-nocomint (funcall bol) (point) t))
  (defun bash-completion-eshell-capf ()
    (bash-completion-capf-1 (lambda () (save-excursion (eshell-bol) (point)))))
  (defun bash-completion-capf ()
    (bash-completion-capf-1 #'point-at-bol))
  (add-hook
   'sh-mode-hook
   (defun mm/add-bash-completion ()
     (add-hook 'completion-at-point-functions #'bash-completion-capf nil t))))

;; Clojure
(use-package cider
  :bind (("C-c M-f" . cider-format-buffer)
         :map clojure-mode-map
         ("C-c C-r r" . cider-eval-print-last-sexp))
  :config
  (setq cider-babashka-parameters "nrepl-server 0"
	clojure-toplevel-inside-comment-form t)

  (cider-register-cljs-repl-type 'nbb-or-scittle-or-joyride "(+ 1 2 3)")

  (defun mm/cider-connected-hook ()
    (when (eq 'nbb-or-scittle-or-joyride cider-cljs-repl-type)
      (setq-local cider-show-error-buffer nil)
      (cider-set-repl-type 'cljs)))
  (add-hook 'cider-connected-hook #'mm/cider-connected-hook)

  (defun simple-easy-clojure-hello ()
    (interactive)
    (unless
	(executable-find "clj")
      (user-error
       "Install clojure first! browsing to %s"
       (let ((url "https://clojure.org/guides/install_clojure")) (browse-url url) url)))
    (let*
	((dir (expand-file-name "simple-easy-clojure-hello" (temporary-file-directory)))
	 (_ (make-directory dir t))
	 (default-directory dir))
      (shell-command "echo '{}' > deps.edn")
      (make-directory "src" t)
      (find-file "src/hello.clj")
      (when (eq (point-min) (point-max))
	(insert "(ns hello)\n\n(defn main []\n  (println \"hello world\"))\n\n\n;; this is a Rich comment, use it to try out pieces of code while you develop.\n(comment\n  (def rand-num (rand-int 10))\n  (println \"Here is the secret number: \" rand-num))"))
      (call-interactively #'cider-jack-in-clj)))

  ;; this is a simpler cider complete that
  ;; that does everything I need together with orderless.
  ;; also complete locals

  (defun mm/cider-complete-at-point ()
    "Complete the symbol at point."
    (when (and (cider-connected-p)
	       (not (cider-in-string-p)))
      (when-let*
	  ((bounds
	    (bounds-of-thing-at-point
	     'symbol))
	   (beg (car bounds))
	   (end (cdr bounds))
	   (completion
	    (append
	     (cider-complete
	      (buffer-substring beg end))
	     (get-text-property (point) 'cider-locals))))
	(list
	 beg
	 end
	 (completion-table-dynamic
	  (lambda (_) completion))
	 :annotation-function #'cider-annotate-symbol))))

  (advice-add 'cider-complete-at-point :override #'mm/cider-complete-at-point))

(use-package vundo
  :ensure t
  :bind (("C-?" . vundo))
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols
	vundo-compact-display t))

(use-package multiple-cursors
  :ensure t
  :bind (("C-." . mc/mark-next-like-this)
	 ("C-." . mc/mark-next-like-this)
	 ("C-." . mc/mark-next-like-this)
	 ("C-/" . 'mc/edit-lines)
	 ("C-S-<mouse-1>" . mc/add-cursor-on-click)))

(use-package magit)

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package sudo-edit
  :ensure t
  :bind (("C-c C-r e" . sudo-edit)))

(use-package rainbow-delimiters)
(rainbow-delimiters-mode)

;; Global key binds  
(global-set-key (kbd "C-c m") 'my-open-magit-persp)                                                    
(global-set-key (kbd "C-z") 'undo)
(global-set-key (kbd "C-S-Z") 'undo-redo)

;; set variables
(setq auto-save-visited-interval 5)
(auto-save-visited-mode)

;; I want M-! (shell-command) to pick up my aliases and so run .bashrc:
(setq shell-file-name "bash-for-emacs.sh")  ; Does this: BASH_ENV="~/.bashrc" exec bash "$@"
(setq shell-command-switch "-c")

;; window undo
(setq winner-mode 1)

(require 'bookmark)
(setq bookmark-save-flag 1)

;; functions
(defun create-scratch-buffer nil
   "create a scratch buffer"
   (interactive)
   (switch-to-buffer (get-buffer-create "*scratch*"))
   (lisp-interaction-mode))
(global-set-key (kbd "C-c C-r n") 'create-scratch-buffer)

;; (read-from-minibuffer
;;  (concat
;;   (propertize "Bold" 'face '(bold default))
;;   (propertize " and normal: " 'face '(default))))

(defun nuke-all-buffers ()
  (interactive)
  (mapcar 'kill-buffer (buffer-list))
  (delete-other-windows))
(global-set-key (kbd "C-x K") 'nuke-all-buffers)

;; layouts
(defun my-idlegame-cli ()
  (interactive)
  (nuke-all-buffers)
  (delete-other-windows)
  (switch-to-buffer (get-buffer-create "logcatusb"))
  (async-shell-command "logcatusb" (current-buffer))
  (split-window-horizontally)
  (switch-to-buffer (get-buffer-create "screencopyusb"))
  (async-shell-command "screencopyusb" (current-buffer))
  (split-window-vertically)
  (other-window 1)
  (switch-to-buffer (get-buffer-create "idlegame-cli"))
  (shell))
