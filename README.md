# framboise-install

Les scripts de génération de l'image pour la Raspberry Pi.

* `custom_raspbian_generate.sh` :
  * Télécharge + check + extrait une image officielle Raspbian
  * Customise l'image avec le script "customization.sh" (updates,…)
  * Le script customization se termine sur un prompt dans le chroot,
    donc vous pouvez continuer à la main.

* `custom_raspbian_continue.sh` : 
  * Ouvre un prompt dans l'image raspbian customizée

* `custom_raspbian_flash.sh` :
  * Demande le device à flasher
  * Flashe l'image customizée
