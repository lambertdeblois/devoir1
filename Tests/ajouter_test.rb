require_relative 'test_helper'

describe "GestionAcademique" do
  describe "ajouter" do
    it_ "ajoute dans un fichier vide" do
      nouveau_contenu = avec_fichier '.cours.txt', [], :conserver do
        execute_sans_sortie_ou_erreur do
          ga( 'ajouter INF1120 "Programmation I" 3' )
        end
      end

      nouveau_contenu.size.must_equal 1
      nouveau_contenu.first.must_equal "INF1120,Programmation I,3,,ACTIF"
      FileUtils.rm_f '.cours.txt'
    end

    it_ "signale une erreur si depot inexistant", :intermediaire do
      FileUtils.rm_f '.cours.txt'
      genere_erreur /fichier.*[.]cours.txt.*existe pas/ do
        ga( 'ajouter INF120 "Programmation I" 3 INF0000 XXX' )
      end
    end

    it_ "signale une erreur si le sigle est invalide", :intermediaire do
      avec_fichier '.cours.txt', [] do
        genere_erreur /Sigle.*incorrect/ do
          ga( 'ajouter INF120 "Programmation I" 3 INF0000 XXX' )
        end
      end
    end

    it_ "signale une erreur si un prealable est invalide au niveau du sigle", :intermediaire do
      avec_fichier '.cours.txt', [] do
        genere_erreur /Sigle.*incorrect/ do
          ga( 'ajouter INF1120 "Programmation I" 3 IF0000' )
        end
      end
    end

    it_ "signale une erreur si un prealable est invalide parce qu'inexistant", :intermediaire do
      avec_fichier '.cours.txt', [] do
        genere_erreur /Prealable.*invalide/ do
          ga( 'ajouter INF1120 "Programmation I" 3 INF1000' )
        end
      end
    end

    it_ "signale une erreur si un prealable est invalide parce qu'inactif", :intermediaire do
      avec_fichier '.cours.txt', [] do
        genere_erreur /Prealable.*invalide/ do
          ga( 'ajouter INF1120 "Programmation I" 3 INF3143' )
        end
      end
    end

    context "banque de cours avec plusieurs cours" do
      let(:lignes) { IO.readlines("Tests/cours.txt.5+1") }

      it_ "ajoute un cours s'il n'existe pas" do
        sigle = 'INF3143'
        titre = 'Modelisation et specification formelle'
        nb_credits = '3'
        prealables = 'INF1130 INF2120'

        nouveau_contenu = avec_fichier '.cours.txt', lignes, :conserver do
          execute_sans_sortie_ou_erreur do
            ga( "ajouter #{sigle} \"#{titre}\" #{nb_credits} #{prealables}" )
          end
        end

        nouveau_contenu.last.must_equal [sigle, titre, nb_credits, prealables.gsub(/ /, ':'), 'ACTIF'].join(",")
        FileUtils.rm_f '.cours.txt'
      end


      it_ "signale une erreur si un prealable est incorrect", :intermediaire do
        avec_fichier '.cours.txt', [] do
          genere_erreur /Prealable.*invalide/ do
            ga( 'ajouter INF2160 "Paradigmes de programmation" 3 INF2120 INF200' )
          end
        end
      end

      it_ "signale une erreur si un prealable est invalide parce qu'inexistant", :intermediaire do
        avec_fichier '.cours.txt', [] do
          genere_erreur /Prealable.*invalide/ do
            ga( 'ajouter INF2160 "Paradigmes de programmation" 3 INF2120 INF2100' )
          end
        end
      end

      it_ "signale une erreur si le cours existe deja", :intermediaire_ do
        avec_fichier '.cours.txt', lignes do
          genere_erreur /meme sigle existe/ do
            ga( 'ajouter INF1130 "Mathematiques" 3' )
          end
        end
      end
    end

    context "banque de cours autre que celui par defaut" do
      let(:lignes) { IO.readlines("Tests/cours.txt.5+1") }
      let(:fichier) { '.foo.txt' }

      it_ "signale une erreur si depot inexistant", :intermediaire do
        FileUtils.rm_f fichier
        genere_erreur /fichier.*#{fichier}.*existe pas/ do
          ga( "--depot=#{fichier} ajouter INF120 'Programmation I' 3 INF0000 XXX" )
        end
      end

      it_ "ajoute un cours s'il n'existe pas", :intermediaire do
        sigle = 'INF3143'
        titre = 'Modelisation et specification formelle'
        nb_credits = '3'
        prealables = 'INF1130 INF2120'

        nouveau_contenu = avec_fichier fichier, lignes, :conserver do
          execute_sans_sortie_ou_erreur do
            ga( "--depot=#{fichier} ajouter #{sigle} \"#{titre}\" #{nb_credits} #{prealables}" )
          end
        end

        nouveau_contenu.last.must_equal [sigle, titre, nb_credits, prealables.gsub(/ /, ':'), 'ACTIF'].join(",")
        FileUtils.rm_f fichier
      end
    end
  end
end
