;;; packages.el --- geolocation configuration File for Spacemacs
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author: Uri Sharf <uri.sharf@me.com>
;; URL: https://github.com/usharf/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(setq geolocation-packages
    '(
      osx-location
      popwin
      rase
      sunshine
      theme-changer
      ))

(defun geolocation/init-osx-location ()
  "Initialize osx-location"
  (use-package osx-location
    :if geolocation-enable-location-service
    :defer t
    :init
    (progn
      (when (spacemacs/system-is-mac)
          (add-hook 'osx-location-changed-hook
                    (lambda ()
                      (let ((location-changed-p nil)
                            (_longitude (/ (truncate (* osx-location-longitude 10)) 10.0)) ; one decimal point, no rounding
                            (_latitdue (/ (truncate (* osx-location-latitude 10)) 10.0)))
                        (unless (equal (bound-and-true-p calendar-longitude) _longitude)
                          (setq calendar-longitude _longitude
                                location-changed-p t))
                        (unless (equal (bound-and-true-p  calendar-latitude) _latitdue)
                          (setq calendar-latitude _latitdue
                                location-changed-p t))
                        (when (and (configuration-layer/layer-usedp 'geolocation) location-changed-p)
                          (message "Location changed %s %s (restarting rase-timer)" calendar-latitude calendar-longitude)
                          (rase-start t)
                          ))))
          (osx-location-watch)))))

(defun geolocation/init-rase ()
  (use-package rase
    :defer t
    :init
    (progn
      (add-hook 'osx-location-changed-hook
                (lambda ()
                  (setq calendar-latitude osx-location-latitude
                        calendar-longitude osx-location-longitude)
                  (unless (bound-and-true-p calendar-location-name)
                    (setq calendar-location-name
                          (format "%s, %s"
                                  osx-location-latitude
                                  osx-location-longitude)))))
      (osx-location-watch)
      (defadvice rase-start (around test-calendar activate)
        "Don't call `raise-start' if `calendar-latitude' or
`calendar-longitude' are not bound yet, or still nil.

This is setup this way because `rase.el' does not test these
values, and will fail under such conditions, when calling
`solar.el' functions.

Also, it allows users who enabled service such as `osx-location'
to not have to set these variables manually when enabling this layer."
        (if (and (bound-and-true-p calendar-longitude)
                 (bound-and-true-p calendar-latitude))
            ad-do-it))
      (rase-start t)
      )))

(defun geolocation/init-sunshine ()
  "Initialize sunshine"
  (use-package sunshine
    :if geolocation-enable-weather-forecast
    :commands (sunshine-forecast sunshine-quick-forecast)
    :init
    (progn
      (spacemacs/set-leader-keys
        "aw" 'sunshine-forecast
        "aW" 'sunshine-quick-forecast))
    :config
    (progn
      (evilified-state-evilify-map sunshine-mode-map
        :mode sunshine-mode
        :bindings
        (kbd "q") 'quit-window
        (kbd "i") 'sunshine-toggle-icons)

      ;; just in case location was not set by user, or on OS X,
      ;; if wasn't set up automatically, will not work with Emac's
      ;; default for ;; `calendar-location-name'
      (when (not (boundp 'sunshine-location))
        (setq sunshine-location (format "%s, %s"
                                        calendar-latitude
                                        calendar-longitude)))
  )))

(defun geolocation/init-theme-changer ()
  "Initialize theme-changer"
  (use-package theme-changer
    :if geolocation-enable-automatic-theme-changer
    :config
    (progn
      (when (> (length dotspacemacs-themes) 1)
        (change-theme (nth 0 dotspacemacs-themes)
                      (nth 1 dotspacemacs-themes))))))

(defun geolocation/post-init-popwin ()
  ;; Pin the weather forecast to the bottom window
  (push '("*Sunshine*" :dedicated t :position bottom)
        popwin:special-display-config))
