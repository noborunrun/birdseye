require 'redmine'

Redmine::Plugin.register :redmine_birdseye do
  name 'Redmine Birdseye plugin'
  author 'Yanagisawa Noboru'
  description 'You will able to use Birds Eyed View.'
  version '0.0.1'

menu :application_menu, :birdseye, { :controller => 'birdseye_main', :action => 'index' }, :caption => 'BirdsEye', :last => true

end
