#This is an example of using CRIMP's addHeaderContent function to add
#a javascript call, which in this case displays some pretty snow

#package decleration. This is needed to tell perl the 'namespace' that this file uses
package Crimp::Snow;

#constructor routing. This is needed to import the $crimp equivelent variable into our namespace.
sub new {
  #get the class name of this module
  my $class = shift;
  #get the crimp object
  my $crimp = shift;
  #another way of doing that would have been `my ($class, $crimp) = @_;`
  
  #set up a self referencing variable that we will use to call any subroutines within this module.
  # this variable will also hold our crimp object, so that any crimp subs or variables can be called
  # with $varname->{crimp}->sub(); or $varname->{crimp}->{variable};. we call this $self for
  # decriptiveness sake as it referrs to this module.
  my $self = { id => q$Id: Snow.pm,v 2.1 2006-07-27 23:12:07 diddledan Exp $, crimp => $crimp, };
  bless $self, $class;
  #the bless command makes the variable part of the namespace.
}

# the main routine
sub execute {
  # bring in the $self object (this will always be the first thing in the @_ array when a new sub is called.
  my $self = shift;
  
  #call a subrouting that is WITHIN this module
  $self->doit;
}

sub doit {
  # bring in the $self object again
  my $self = shift;
  # define the $crimp variable for quicker access
  my $crimp = $self->{crimp};
  #call one of CRIMP's subs to add our content
  $crimp->addHeaderContent('<script type="text/javascript" src="/crimp_assets/js/snow.js"></script>');
}

#return a true value to indicate proper loading of the module
1;
