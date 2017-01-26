require_relative 'test_helper'

describe "GestionAcademique" do
  describe "nb_credits" do
    context "banque de cours avec plusieurs cours" do
      let(:lignes) { IO.readlines("Tests/cours.txt.5+1") }

      it_ "retourne 0 si aucun sigle indique" do
        avec_fichier '.cours.txt', lignes do
          genere_sortie ["0"] do
            ga( 'nb_credits' )
          end
        end
      end

      it_ "retourne la somme des credits si plusieurs sigles" do
        avec_fichier '.cours.txt', lignes do
          genere_sortie ["9"] do
            ga( 'nb_credits INF1120 INF1130 INF3135' )
          end
        end
      end

      it_ "signale une erreur si un sigle n'existe pas", :intermediaire do
        avec_fichier '.cours.txt', lignes do
          genere_erreur /Aucun cours.*INF1111/ do
            ga( 'nb_credits INF1130 INF1111 INF3135' )
          end
        end
      end
    end
  end
end
