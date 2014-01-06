use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::finddups::bloom',
  VERSION_FROM => 'lib/App/finddups/bloom.pm',
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
README : script/finddups-bloom
	pod2text script/finddups-bloom > README
";
}
