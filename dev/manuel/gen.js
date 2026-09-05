const fs = require("fs");
const d = require("docx");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle, Header,
  PageBreak, Footer, PageNumber, TableOfContents, LevelFormat, convertInchesToTwip
} = d;

const CATALOGUE = JSON.parse(fs.readFileSync("./catalogue.json", "utf8"));

// Le manuel de reference est compose en LaTeX, avec une serif classique et
// une mise en page sobre : pas d'aplat de couleur, des filets fins, des
// encadres a fond tres clair. Les couleurs vives de la premiere version sont
// donc abandonnees au profit de gris et de noir.
const NOIR = "000000", GRIS_TEXTE = "3A3A3A", FILET = "9A9A9A";
const BLEU = "3A3A3A", OR = "808080", GRIS = "F2F2F2", ENCADRE = "EFEFEF";
const SERIF = "Cambria";
const L = 11906, H = 16838, MARGE = 1276;
const UTILE = L - 2 * MARGE; // 9354

function p(t, o = {}) {
  return new Paragraph({
    children: [new TextRun({ text: t, size: o.size || 21, bold: !!o.b, italics: !!o.i, color: o.color })],
    spacing: { after: o.after === undefined ? 140 : o.after, line: 288 },
    alignment: o.align || AlignmentType.JUSTIFIED,
  });
}

function liste(t, ref) {
  return new Paragraph({
    children: [new TextRun({ text: t, size: 21 })],
    numbering: { reference: ref, level: 0 },
    spacing: { after: 90, line: 288 },
    alignment: AlignmentType.JUSTIFIED,
  });
}

function cellule(txt, w, o = {}) {
  return new TableCell({
    width: { size: w, type: WidthType.DXA },
    shading: o.fond ? { type: ShadingType.CLEAR, fill: o.fond, color: "auto" } : undefined,
    margins: o.dense
      ? { top: 24, bottom: 24, left: 70, right: 70 }
      : { top: 60, bottom: 60, left: 90, right: 90 },
    borders: o.sansBord ? {
      top: { style: BorderStyle.SINGLE, size: 4, color: FILET },
      bottom: { style: BorderStyle.SINGLE, size: 4, color: FILET },
      left: { style: BorderStyle.SINGLE, size: 4, color: FILET },
      right: { style: BorderStyle.SINGLE, size: 4, color: FILET },
    } : undefined,
    children: (Array.isArray(txt) ? txt : [txt]).map((x, i) =>
      new Paragraph({
        children: [new TextRun({
          text: x, bold: !!o.b || (o.encadre && i === 0),
          color: o.b ? "FFFFFF" : NOIR,
          size: o.size || 18, font: o.mono ? "Consolas" : undefined,
        })],
        spacing: { after: i === 0 && (Array.isArray(txt) && txt.length > 1) ? 70 : 0,
                   line: o.encadre ? 276 : (o.dense ? 200 : 240) },
        alignment: o.encadre && i > 0 ? AlignmentType.JUSTIFIED : AlignmentType.LEFT,
      })),
  });
}

// Encadre : cellule unique sur fond clair, filet dore a gauche.
function encadre(titre, texte) {
  return new Table({
    columnWidths: [UTILE],
    width: { size: UTILE, type: WidthType.DXA },
    rows: [new TableRow({
      children: [cellule([titre, texte], UTILE, { fond: ENCADRE, encadre: true, size: 19, sansBord: true })],
    })],
  });
}

function tableau(entetes, lignes, largeurs, o = {}) {
  return new Table({
    columnWidths: largeurs,
    width: { size: UTILE, type: WidthType.DXA },
    rows: [
      new TableRow({
        tableHeader: true,
        children: entetes.map((h, i) => cellule(h, largeurs[i],
          { b: true, fond: BLEU, dense: o.dense, size: o.size })),
      }),
      ...lignes.map((l, i) => new TableRow({
        children: l.map((c, j) => cellule(String(c), largeurs[j], {
          fond: i % 2 ? GRIS : undefined,
          mono: o.mono && o.mono.includes(j),
          size: o.size, dense: o.dense,
        })),
      })),
    ],
  });
}

function repartir(n) {
  if (n === 2) return [3100, UTILE - 3100];
  if (n === 3) return [2500, 3500, UTILE - 6000];
  return new Array(n).fill(Math.floor(UTILE / n));
}

function construire(T) {
  const enfants = [];
  const garde = [];
  // ------------------------------------------------------- page de garde
  // Meme agencement que le manuel OPESc 4.2 : la marque en haut, puis le
  // titre, le sous-titre, la version, et en bas le service, le ministere et
  // la date. Aucun filet, aucun aplat : la sobriete du document de reference.
  garde.push(
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 2400 },
      children: [new TextRun({ text: T.marque, bold: true, size: 40, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 140 },
      children: [new TextRun({ text: T.titre, bold: true, size: 44, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 280 },
      children: [new TextRun({ text: T.sousTitre, size: 26, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 2600 },
      children: [new TextRun({ text: T.version, size: 24, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 70 },
      children: [new TextRun({ text: T.service, size: 22, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 70 },
      children: [new TextRun({ text: T.ministere, size: 22, color: NOIR })] }),
    new Paragraph({ alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: T.date, size: 22, color: NOIR })] }),
  );


  const tableaux = [];      // pour la liste des tableaux
  let numTable = 0, numTableChapitre = 0;

  const h1 = (t) => new Paragraph({ text: t, heading: HeadingLevel.HEADING_1,
                                    spacing: { before: 0, after: 260 } });
  // Les sous-titres portent leur numero de section, 1.1, 1.2, comme dans le
  // manuel de reference. Le compteur est remis a zero a chaque chapitre.
  let chapitreCourant = 0, sectionCourante = 0;
  const h2 = (t) => {
    sectionCourante += 1;
    const prefixe = chapitreCourant > 0 ? `${chapitreCourant}.${sectionCourante} ` : "";
    return new Paragraph({ text: prefixe + t, heading: HeadingLevel.HEADING_2 });
  };

  function rendre(blocs) {
    blocs.forEach((b) => {
      switch (b[0]) {
        case "h2": enfants.push(h2(b[1])); break;
        case "p": enfants.push(p(b[1])); break;
        case "l": b[1].forEach((x) => enfants.push(liste(x, "puces"))); break;
        case "ol": b[1].forEach((x) => enfants.push(liste(x, "nombres"))); break;
        case "enc":
          enfants.push(encadre(b[1], b[2]));
          enfants.push(p("", { after: 200 }));
          break;
        case "tab": {
          numTable += 1; numTableChapitre += 1;
          const rang = chapitreCourant > 0
            ? `${chapitreCourant}.${numTableChapitre}` : String(numTable);
          const titre = `${T.tableau} ${rang}. ${b[1]}`;
          tableaux.push(titre);
          enfants.push(tableau(b[2], b[3], repartir(b[2].length)));
          enfants.push(new Paragraph({
            children: [new TextRun({ text: titre, size: 17, italics: true, color: "5C6672" })],
            spacing: { before: 90, after: 220 }, alignment: AlignmentType.CENTER,
          }));
          break;
        }
        case "cat":
          CATALOGUE.forEach((cat) => {
            enfants.push(h2(`${cat.code}. ${cat[T.langue]}`));
            const sources = [...new Set(cat.indicateurs.map((i) => i.source))];

            // Au-dela de cinquante lignes, le tableau passe sur deux colonnes
            // de paires. La colonne des unites y est omise : ces series
            // partagent les memes unites de cotation, indiquees en note, et
            // les repeter cent fois coutait trois pages pour rien.
            if (cat.indicateurs.length > 50) {
              const n = cat.indicateurs.length;
              const moitie = Math.ceil(n / 2);
              const lignes = [];
              for (let k = 0; k < moitie; k++) {
                const g = cat.indicateurs[k];
                const d2 = cat.indicateurs[k + moitie];
                lignes.push([g[T.langue], g.code,
                             d2 ? d2[T.langue] : "", d2 ? d2.code : ""]);
              }
              enfants.push(tableau(
                [T.entetesCatalogue[0], T.entetesCatalogue[1],
                 T.entetesCatalogue[0], T.entetesCatalogue[1]],
                lignes, [3000, 1677, 3000, 1677],
                { mono: [1, 3], size: 14, dense: true }));
            } else {
              enfants.push(tableau(
                T.entetesCatalogue,
                cat.indicateurs.map((i) => [i[T.langue], i.code, i.unite || T.sansUnite]),
                [4300, 2300, 2754], { mono: [1], size: 15, dense: true }));
            }
            enfants.push(new Paragraph({
              children: [new TextRun({
                text: `${T.sourceLabel} ${sources.join(", ")}`,
                size: 16, italics: true, color: "5C6672" })],
              spacing: { before: 70, after: 180 },
            }));
            enfants.push(p("", { after: 160 }));
          });
          break;
      }
    });
  }

  // ---------------------------------------------------------- sommaires
  // La table est composee ligne a ligne plutot que confiee au champ de Word :
  // ce champ reste vide tant que le document n'est pas ouvert et actualise,
  // ce qui donne une table blanche dans le PDF et pour qui lit sans Word.
  const pages = T.pagination || {};
  enfants.push(h1(T.sommaire));
  const entrees = [];
  entrees.push({ titre: T.resume, niveau: 1 });
  T.chapitres.forEach((c, i) => {
    entrees.push({ titre: `${i + 1}. ${c.t}`, niveau: 1 });
    c.blocs.forEach((b) => {
      if (b[0] === "h2") entrees.push({ titre: b[1], niveau: 2 });
    });
  });
  const lettres2 = "ABCDEFGH";
  T.annexes.forEach((a, i) => {
    entrees.push({ titre: `${T.annexe} ${lettres2[i]}. ${a.t}`, niveau: 1 });
  });

  entrees.forEach((e, rang) => {
    const numero = pages[String(rang)];
    enfants.push(new Paragraph({
      tabStops: [{ type: "right", position: UTILE, leader: "dot" }],
      spacing: { after: e.niveau === 1 ? 60 : 30, line: 240 },
      indent: e.niveau === 2 ? { left: 340 } : undefined,
      children: [
        new TextRun({ text: e.titre, size: e.niveau === 1 ? 21 : 19,
                      bold: e.niveau === 1, color: e.niveau === 1 ? BLEU : "3C4650" }),
        new TextRun({ text: "\t" + (numero === undefined ? "" : String(numero)),
                      size: 19, color: "5C6672" }),
      ],
    }));
  });
  enfants.push(new Paragraph({ children: [new PageBreak()] }));
  const positionListeTableaux = enfants.length;   // remplie apres le rendu
  enfants.push(new Paragraph({ children: [new PageBreak()] }));

  // ----------------------------------------------------- resume executif
  enfants.push(h1(T.resume));
  rendre(T.resumeBlocs);
  enfants.push(new Paragraph({ children: [new PageBreak()] }));

  // ------------------------------------------------------------ chapitres
  T.chapitres.forEach((c, i) => {
    chapitreCourant = i + 1;
    sectionCourante = 0;
    numTableChapitre = 0;
    enfants.push(new Paragraph({
      children: [new TextRun({ text: `${T.chapitre} ${i + 1}`, size: 26, color: NOIR })],
      spacing: { before: 0, after: 120 },
    }));
    enfants.push(h1(c.t));
    rendre(c.blocs);
    enfants.push(new Paragraph({ children: [new PageBreak()] }));
  });

  // -------------------------------------------------------------- annexes
  const lettres = "ABCDEFGH";
  T.annexes.forEach((a, i) => {
    chapitreCourant = 0;
    sectionCourante = 0;
    enfants.push(new Paragraph({
      children: [new TextRun({ text: `${T.annexe} ${lettres[i]}`, size: 26, color: NOIR })],
      spacing: { before: 0, after: 120 },
    }));
    enfants.push(h1(a.t));
    rendre(a.blocs);
    // Seule l'annexe du catalogue commence sur une nouvelle page : les autres
    // sont breves et s'enchainent sans laisser de blanc.
    if (i === 0) enfants.push(new Paragraph({ children: [new PageBreak()] }));
  });

  // Liste des tableaux, inseree une fois la numerotation connue.
  const liste_tab = [h1(T.listeTableaux)];
  tableaux.forEach((t) => liste_tab.push(p(t, { after: 70, align: AlignmentType.LEFT })));
  enfants.splice(positionListeTableaux, 0, ...liste_tab);

  const miseEnPage = { page: { size: { width: L, height: H },
    margin: { top: MARGE, bottom: MARGE, left: MARGE, right: MARGE } } };

  const enteteCourant = new Header({ children: [new Paragraph({
    tabStops: [{ type: "right", position: UTILE }],
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: FILET } },
    spacing: { after: 200 },
    children: [
      new TextRun({ text: T.enteteGauche, size: 17, color: GRIS_TEXTE }),
      new TextRun({ text: "\t" + T.servicePied, size: 17, color: GRIS_TEXTE })],
  })] });

  const piedCourant = new Footer({ children: [new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ children: [PageNumber.CURRENT], size: 18,
                             color: GRIS_TEXTE })],
  })] });

  return new Document({
    creator: "OPESc+", title: `${T.plateforme} : ${T.titre}`,
    numbering: { config: [
      { reference: "puces", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2013",
        alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: convertInchesToTwip(0.32), hanging: convertInchesToTwip(0.2) } } } }] },
      { reference: "nombres", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.",
        alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: convertInchesToTwip(0.36), hanging: convertInchesToTwip(0.24) } } } }] },
    ] },
    styles: { default: {
      document: { run: { font: SERIF, size: 21 } },
      heading1: { run: { font: SERIF, size: 34, bold: true, color: NOIR },
                  paragraph: { spacing: { before: 200, after: 180 } } },
      heading2: { run: { font: SERIF, size: 25, bold: true, color: NOIR },
                  paragraph: { spacing: { before: 240, after: 120 } } },
    } },
    sections: [{
      properties: miseEnPage,
      children: garde,
    }, {
      properties: { ...miseEnPage, titlePage: false },
      headers: { default: enteteCourant },
      footers: { default: piedCourant },
      children: enfants,
    }],
  });
}

["fr", "en"].forEach((langue) => {
  const T = JSON.parse(fs.readFileSync(`./contenu_${langue}.json`, "utf8"));
  Packer.toBuffer(construire(T)).then((b) => {
    const nom = `manuel_opesc_${langue}.docx`;
    fs.writeFileSync(nom, b);
    console.log(`${nom} : ${(b.length / 1024).toFixed(0)} Ko`);
  });
});
