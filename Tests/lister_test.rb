require_relative 'test_helper'

describe "GestionAcademique" do
  describe "lister" do
    it_ "signale une erreur si fichier inexistant", :intermediaire do
      FileUtils.rm_f '.cours.txt'
      genere_erreur /fichier.*[.]cours.txt.*existe pas/ do
        ga( 'lister' )
      end
    end

    it_ "liste un fichier vide" do
      avec_fichier '.cours.txt'do
        execute_sans_sortie_ou_erreur do
          ga( 'lister' )
        end
      end
    end

    it_ "liste uniquement, par defaut, les cours actifs" do
      lignes = IO.readlines("Tests/cours.txt.5+1")
      attendu = ['INF1120 "Programmation I" ()',
                 'INF1130 "Mathematiques pour informaticien" ()',
                 'INF2120 "Programmation II" (INF1120)',
                 'INF3105 "Structures de donnees et algorithmes" (INF1130:INF2120)',
                 'INF3135 "Construction et maintenance de logiciels" (INF1120)',
                ]

      avec_fichier '.cours.txt', lignes do
        genere_sortie attendu do
          ga( 'lister' )
        end
      end
    end

    it_ "liste les cours inactifs si requis", :intermediaire do
      lignes = IO.readlines("Tests/cours.txt.5+1")
      attendu = ['INF1120 "Programmation I" ()',
                 'INF1130 "Mathematiques pour informaticien" ()',
                 'INF2120 "Programmation II" (INF1120)',
                 'INF3105 "Structures de donnees et algorithmes" (INF1130:INF2120)',
                 'INF3135 "Construction et maintenance de logiciels" (INF1120)',
                 'MAT3140? "Algebre et logique" ()',
                ]
      avec_fichier '.cours.txt', lignes do
        genere_sortie attendu do
          ga( 'lister --avec_inactifs' )
        end
      end
    end

    it_ "genere une erreur si arguments en trop", :intermediaire do
      lignes = IO.readlines("Tests/cours.txt.5+1")
      attendu = ['INF1120 "Programmation I" ()',
                 'INF1130 "Mathematiques pour informaticien" ()',
                 'INF2120 "Programmation II" (INF1120)',
                 'INF3105 "Structures de donnees et algorithmes" (INF1130:INF2120)',
                 'INF3135 "Construction et maintenance de logiciels" (INF1120)',
                 'MAT3140? "Algebre et logique" ()',
                ]
      avec_fichier '.cours.txt', lignes do
        genere_sortie_et_erreur attendu, /Argument.*en trop/ do
          ga( 'lister --avec_inactifs foo' )
        end
      end
    end

    context "banque de cours autre que celui par defaut" do
      let(:lignes) { IO.readlines("Tests/cours.txt.5+1") }
      let(:fichier) { '.foo.txt' }

      it_ "signale une erreur si depot inexistant", :intermediaire do
        FileUtils.rm_f fichier
        genere_erreur /fichier.*#{fichier}.*existe pas/ do
          ga( "--depot=#{fichier} lister" )
        end
      end

      it_ "ajoute un cours s'il n'existe pas", :intermediaire do
        attendu = ['INF1120 "Programmation I" ()',
                   'INF1130 "Mathematiques pour informaticien" ()',
                   'INF2120 "Programmation II" (INF1120)',
                   'INF3105 "Structures de donnees et algorithmes" (INF1130:INF2120)',
                   'INF3135 "Construction et maintenance de logiciels" (INF1120)',
                  ]

        avec_fichier fichier, lignes do
          genere_sortie attendu do
            ga( "--depot=#{fichier} lister" )
          end
        end
      end
    end
  end
end
