# Composition des manuels

Deux chaînes, un seul contenu.

| Fichier | Rôle |
|---|---|
| `contenu_fr.json`, `contenu_en.json` | texte du manuel, chapitres et annexes |
| `catalogue.json` | les 341 indicateurs, par catégorie |
| `gen_latex.py` | compose le PDF, avec la page de garde de référence |
| `gen.js` | compose le Word |
| `gen_note.py` | note de présentation, dix pages |
| `gen_guide.py` | guide technique, huit pages |

Le PDF passe par LaTeX parce que le manuel de référence en vient : la page de
garde et la typographie s'y reproduisent exactement, ce qu'un traitement de
texte ne permet qu'approximativement. Le Word reste produit par la
bibliothèque `docx`, un DOCX issu de LaTeX étant toujours dégradé.

## Régénérer

```bash
python3 gen_latex.py     # manuel, PDF
node gen.js              # manuel, Word
python3 gen_note.py      # note de présentation
python3 gen_guide.py     # guide technique
```

Effacez les fichiers auxiliaires de LaTeX entre deux compositions, sans quoi le
sommaire garde une numérotation périmée. `gen_guide.py` le fait de lui-même,
les deux autres non.

Puis copier les quatre fichiers dans `inst/app/www/manuel` et
`inst/extdata/manuel`.

## Modifier le contenu

Tout est dans les deux fichiers JSON. Chaque chapitre est une liste de blocs :

- `["p", "texte"]` paragraphe
- `["h2", "titre"]` sous-titre, numéroté automatiquement
- `["l", [...]]` liste à puces, `["ol", [...]]` liste numérotée
- `["enc", "titre", "texte"]` encadré
- `["tab", "légende", [entêtes], [[lignes]]]` tableau
- `["cat"]` insère le catalogue des indicateurs

Les deux langues doivent être modifiées de pair : rien ne les synchronise.

## Régénérer le catalogue après un changement du catalogue de la plateforme

`catalogue.json` est produit à partir de `inst/extdata/catalogue.csv` et des
libellés anglais. Il faut le refaire quand des indicateurs sont ajoutés ou
renommés, faute de quoi le manuel décrira un périmètre périmé.
