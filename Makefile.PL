use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	    => 'URI::Bookmarks',
    'VERSION_FROM'  => 'Bookmarks.pm',
    'ABSTRACT_FROM' => 'Bookmarks.pm',
    'PREREQ_PM'     => { 'Tree::DAG_Node' => 0 },
    'PMLIBDIRS'     => [ 'Bookmarks', 'Bookmark' ],
);
