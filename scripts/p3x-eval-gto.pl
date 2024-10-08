=head1 Evaluate a GenomeTypeObject

    p3x-eval-gto.pl [options] gtoFile outFile htmlFile

This script evaluates a single L<GenomeTypeObject> and stores the quality data back into it.

=head2 Parameters

The positional parameters are the file name of the L<GenomeTypeObject>, the name of the output file for the evaluation results, and the name of a web page file
for the quality analysis.

Additional command-line options are as follows:

=over 4

=item ref

The PATRIC ID of a reference genome to use for comparison.  If specified, the C<deep> option is implied.

=item deep

If specified, the genome is compared to a reference genome in order to provide more details on problematic roles.
If this option is specified and C<ref> is not specified, a reference genome will be computed.

=item evalDir

The name of the directory containing the evaluation files. The default is C<Eval> in the global data directory.

=item template

The name of the template file. The default is C<p3_code/lib/BinningReports/webdetails.tt> in the SEEDtk module directory.

=item external

If specifed, the incoming genome is presumed to be external, and no contig links will be generated on the web page.

=item binned

If specified, the incoming genome is presumed to have external contig IDs which are stored in the description fields of
the sequences in PATRIC.

=item parallel

The number of parallel processes to run when applying the function predictors. The default is C<8>.

=item improve

If specified, the name of a FASTA file.  A reduced set of contigs representing an improved genome will be written to
this file, if an improvement is possible.

=item workDir

Name of a working directory for creating the matrix.  If none is specified, a temporary directory will be used.

=item checkDir

The name of the directory containing the reference genome table and the completeness data files. The default
is to use the directory computed by C<--evalDir>.

=item predictors

The name of the directory containing the role definition files and the function predictors for the consistency
checking. The default is to use the directory computed by C<--evalDir>.


=back

=cut

use strict;
use P3DataAPI;
use P3Utils;
use EvalHelper;
use GenomeTypeObject;

# Get the command-line options.
my $opt = P3Utils::script_opts('gtoFile outFile outHtml',
        ['ref|r=s', 'reference genome ID (implies deep)'],
        ['deep', 'if specified, the genome is compared to a reference genome for more detailed analysis'],
        ['evalDir|eval=s', 'evaluation data directory', { default => "$FIG_Config::p3data/Eval" }],
        ['checkDir=s', 'completeness data directory'],
        ['predictors=s', 'function predictors directory'],
        ['template=s', 'template for web pages', { default => "$FIG_Config::mod_base/p3_code/lib/BinningReports/webdetails.tt" }],
        ['external', 'the genome is not currently installed in PATRIC'],
        ['binned', 'the genome contig IDs are user-suppled, not PATRIC-generated'],
        ['improve=s', 'name of a FASTA file to contain an improved version of the GTO contigs'],
        ['parallel=i', 'parallelism to use in matrix evaluation', { default => 8 }],
        ['workDir=s', 'name of a working directory for the evaluation matrix'],
        ['genomeBaseUrl=s', 'Base path for PATRIC/BVBRC genome page'],
        );
# Get access to PATRIC.
my $p3 = P3DataAPI->new();
# Get the input parameters.
my ($gtoFile, $outFile, $outHtml) = @ARGV;
if (! $gtoFile) {
    die "No input GTO file specified.";
} elsif (! $outFile) {
    die "No output data file specified.";
} elsif (($opt->ref || $opt->deep) && ! $outHtml) {
    die "No output web page file specified.";
}
# Read in the GTO.
my $gto = GenomeTypeObject->create_from_file($gtoFile);
if (! $gto) {
    die "Invalid or missing gto file $gtoFile.";
}
# Call the main processor.
my $checkDir = $opt->checkdir // ($opt->evaldir . "/CheckR");
my $funcDir = $opt->predictors // ($opt->evaldir . "/FunctionPredictors");
my $geo = EvalHelper::ProcessGto($gto, 'ref' => $opt->ref, deep => $opt->deep, checkDir => $checkDir, predictors => $funcDir,
				 parallel => $opt->parallel, workDir => $opt->workdir,
				 p3 => $p3, outFile => $outFile, outHtml => $outHtml, template => $opt->template, external => $opt->external, binned => $opt->binned,
				 improve => $opt->improve,
				 ($opt->genomebaseurl ? (outputGenomeBaseURL => $opt->genomebaseurl) : ()),
				);
# Write the results.
$gto->destroy_to_file($gtoFile);

