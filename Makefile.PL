use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::finddups::bloom',
  VERSION_FROM => 'script/finddups-bloom',
  PREREQ_PM =>
  {
    Bloom::Faster => 0,
    Digest::CRC   => 0,
    Pod::Usage    => 0,
  },
);

package MY;
sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
";
}
