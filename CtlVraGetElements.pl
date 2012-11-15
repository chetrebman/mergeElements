use strict;

# use module
use XML::Simple;
use Data::Dumper;
use Scalar::Util qw/blessed reftype/;

my $XML_DIR     = "/home/chet/alora/xml/";
my $NO_HASH_KEY = "NO_HASH_KEY";

my $file  = "";
my $xml   = new XML::Simple( ForceArray => 1 );
my $initFlag = 0;
my $data  = "";
my $data2 = "";
my $totalFilesMerged = 1;
my $totalFilesFailed = 0;
my $TEXT_REPLACE_TOKEN = "TEXT_ONLY";

opendir( DIR, $XML_DIR ) or die "can't oper $XML_DIR";
while ( defined( $file = readdir(DIR) ) ) {
	if ( $initFlag == 0 ) {
		if ( ( $file eq "." ) or ( $file eq ".." ) ) {
			next;
		}
		eval {
			$data = $xml->XMLin( $XML_DIR . $file );
####			removeText( $NO_HASH_KEY, $data );
			$initFlag++;
		};
		if ($@) {
			### catch block
			print "Failed $XML_DIR . $file \n";
			$totalFilesFailed++;
			next;
		}	
	}
	else {
		eval {
			$data2 = $xml->XMLin( $XML_DIR . $file );
####			removeText( $NO_HASH_KEY, $data2 );
		};
		if ($@) {
			### catch block
			print "Failed $XML_DIR . $file \n";
			$totalFilesFailed++;
			next;
		}
		
		mergeArrays( $NO_HASH_KEY, $data2, $data );
		
#		if ( $initFlag++ >= 1000 ){
#			print $initFlag;
#			closedir(DIR);
#			print Dumper($data);
#			exit;
#		}
		
		$totalFilesMerged++;
	}
}
closedir(DIR);

print Dumper($data);

print "\n\nTotal files merged= $totalFilesMerged, total failed=$totalFilesFailed";

exit;

sub processRawVraFile {
	my ($fileName) = @_;
	print $fileName. "\n";

	getAllElementTypes($fileName);

	#	getAllElementTypesSIMPLE( $fileName );
}

sub getAllElementTypes {
	my ($fileName) = @_;
	open( FILE, "< $fileName" ) or die "Can't open $fileName for reading";
	while ( defined( my $line = <FILE> ) ) {
		print "$line\n";
	}
}

sub test {

	# or (see note about each() above)
	my %HoH = (
		flintstones => {
			husband => "fred",
			wife    => "wilma",
			pal     => "barney",
		},
		jetsons => {
			husband   => "george",
			wife      => "jane",
			"his boy" => "elroy",    # Key quotes needed.
		},
		simpsons => {
			husband => "homer",
			wife    => "marge",
			kid     => "bart",
		},
	);

	foreach my $family ( keys %HoH ) {
		while ( my ( $key, $value ) = each %{ $HoH{$family} } ) {
			print "$key = $value \n";
		}
	}

}

sub SimpleTest {
	my $raw = <<EOF;
<?xml version='1.0'?>
<employees>
	<agentSet>
		<agent>
			<name vocab='ULAN' type='other'>RAW vocab</name>
			<nationality>RAW Nationality</nationality>
		</agent>
	</agentSet>
	<employee>
		<name>John Doe</name>
		<age>43</age>
		<sex>M</sex>
		<department>Operations</department>
	</employee>
	<employee>
		<name>Jane Doe</name>
		<age>31</age>
		<sex>F</sex>
		<department>Accounts</department>
	</employee>
	<employee>
		<name>Be Goode</name>
		<age>32</age>
		<sex>M</sex>
		<department>Human Resources</department>
	</employee>
</employees>
EOF

	# create object
	my $xml = new XML::Simple( ForceArray => 1 );

	# read XML file

	my $data = $xml->XMLin("/home/chet/alora/xml/00042027_vra.xml");

	# read XML file
	my $rawdata = $xml->XMLin($raw);

	my $data2 = $xml->XMLin("/home/chet/alora/xml/00042733_vra.xml");

	#	print Dumper($data);

	print "\n\nPASS 1 \n\n";

	removeText( $NO_HASH_KEY, $rawdata );
	removeText( $NO_HASH_KEY, $data );
	removeText( $NO_HASH_KEY, $data2 );

	print Dumper($rawdata);

	mergeArrays( $NO_HASH_KEY, $data2, $data );

	print "\n\nPASS 2 \n\n";

	print Dumper($data);

	exit;
}

sub mergeArrays {
	my ($hashKey)          = $_[0];
	my ($incomingArrayRef) = $_[1];
	my ($MASTER_ARRAY_REF) = $_[2];

	my $type      = reftype($incomingArrayRef);
	my $Mastertype = reftype($MASTER_ARRAY_REF);

	if ( !defined($type) ) {
		if ( $hashKey ne $NO_HASH_KEY ) {
			foreach my $key ( keys %{$incomingArrayRef} ) {
				mergeArrays( $key, $incomingArrayRef, $MASTER_ARRAY_REF );
			}
		}
		else {

			# at this point we have the actual text.
			return;
		}
	}

    # A hash array my contain any number of child elements (keys)
	if ( $type eq "HASH" ) {
		if ( $hashKey ne $NO_HASH_KEY ) {
	
			# if master array does not have the key, add it. The value maybe text or the entire leg of the tree that is missing.
my $TEST = reftype($MASTER_ARRAY_REF);
if ( !defined($TEST) )
{
	print "ERROR";
}
			if ( !${$MASTER_ARRAY_REF}{$hashKey} ) {
				${$MASTER_ARRAY_REF}{$hashKey} = ${$incomingArrayRef}{$hashKey};
				return;
			}

			foreach my $nextArray ( ${$incomingArrayRef}{$hashKey} ) 
			{	

				mergeArrays( $NO_HASH_KEY, $nextArray, ${$MASTER_ARRAY_REF}{$hashKey} );
			}
		}
		else {
			foreach my $key ( keys %{$incomingArrayRef} ) {
				# print "$key=";				
	
				mergeArrays( $key, $incomingArrayRef, $MASTER_ARRAY_REF );

			}
		}
	}

    # An array will only have two type of elements, any number of text and or 0..1 hash array of children. 
	if ( $type eq "ARRAY" ) 
	{	
#		my $masterIndexType0 = reftype( @{$MASTER_ARRAY_REF}[0] );
#		my $masterIndexType1 = reftype( @{$MASTER_ARRAY_REF}[1] );
		
		my $incomingArraySize = @{$incomingArrayRef};
		my $arrayIndex=0;	
		for ( $arrayIndex=0; $arrayIndex < $incomingArraySize; $arrayIndex++ )
		{		
				if ( !defined($Mastertype) ){
					print "teswt"; #TBD
				}
				if ( $Mastertype eq "HASH" ){
					print "teswt"; #TBD
				}
				
			my $incomingIndexType = reftype( @{$incomingArrayRef}[$arrayIndex] );
			if ( !defined( $incomingIndexType ) ) {
				# if incoming array is text, move it the first text element in the master array overwriting what is there.
				# We don't want to match for the actual text and all we care about is that the parent elment contains text.
				
				if ( !defined($Mastertype) ){
					print "teswt"; #TBD
				}
				if ( $Mastertype eq "HASH" ){
					print "teswt"; #TBD
				}
				
				if ( $Mastertype eq "ARRAY" ) {
					my $masterArraySize = @{$MASTER_ARRAY_REF};
					my $masterArrayIndex=0;	
					for ( $masterArrayIndex=0; $masterArrayIndex < $masterArraySize; $masterArrayIndex++ ) {
						my $masterIndexType = reftype( @{$MASTER_ARRAY_REF}[$masterArrayIndex] );
						if ( !defined( $masterIndexType ) ){
							# the master array has a text so overwrite it with incoming text, we could also just do a return here.
							@{$MASTER_ARRAY_REF}[$masterArrayIndex] = @{$incomingArrayRef}[$arrayIndex]; 
							return;	
						}
					} # if we got here the master array didn't have a text field in the master array, so add it to the end.
					@{$MASTER_ARRAY_REF}[ $masterArraySize ]  = @{$incomingArrayRef}[$arrayIndex];  
				}
			}
			if ( $incomingIndexType eq 'HASH' ) {
				# incoming array has hash so merge it hash in master array	
		
		if ( !defined($Mastertype) ){
					print "teswt"; #TBD
				}
				if ( $Mastertype eq "HASH" ){
					print "teswt"; #TBD
				}
				
				if ( $Mastertype eq "ARRAY" ) {
					my $masterArraySize = @{$MASTER_ARRAY_REF};
					my $masterArrayIndex=0;	
					for ( $masterArrayIndex=0; $masterArrayIndex < $masterArraySize; $masterArrayIndex++ ) {
						my $masterIndexType = reftype( @{$MASTER_ARRAY_REF}[$masterArrayIndex] );
						if ( $masterIndexType eq 'HASH' ) {
							# the master array has a hash so merge incoming hash with with it.
							mergeArrays( $NO_HASH_KEY, @{$incomingArrayRef}[$arrayIndex], @{$MASTER_ARRAY_REF}[ $masterArrayIndex ], );
							return;	
						}
					} # if we got here the master array didn't have a hash, so make an empty one.
					@{$MASTER_ARRAY_REF}[$masterArraySize] = {};
					mergeArrays( $NO_HASH_KEY, @{$incomingArrayRef}[$arrayIndex], @{$MASTER_ARRAY_REF}[ $masterArraySize ], );
				}
				
#				if ( $masterIndexType1 ne 'HASH' ) {
#					# if master array doesn't have a hash yet put in an empty one.
#					@{$MASTER_ARRAY_REF}[1] = {}
#				}
	
				mergeArrays( $NO_HASH_KEY, @{$incomingArrayRef}[$arrayIndex], @{$MASTER_ARRAY_REF}[ 1 ], );	
			}
			if ( $incomingIndexType eq 'ARRAY' ) {
				return;
				mergeArrays( $NO_HASH_KEY, @{$incomingArrayRef}[$arrayIndex], @{$MASTER_ARRAY_REF}[ 1 ], );		
			}
		}
	}
}

sub removeText {
	my ($hashKey)          = $_[0];
	my ($incomingArrayRef) = $_[1];

	my $type = reftype($incomingArrayRef);

	if ( !defined($type) ) {
		if ( $hashKey ne $NO_HASH_KEY ) {
			foreach my $key ( keys %{$incomingArrayRef} ) {
				removeText( $key, $incomingArrayRef );
			}
		}
		else {

			return;
		}
	}

	if ( $type eq "HASH" ) {
		if ( $hashKey ne $NO_HASH_KEY ) {

			foreach my $nextArray ( ${$incomingArrayRef}{$hashKey} ) {

				my $type = reftype($nextArray);
				if ( !defined($type) ) {
					$nextArray = $TEXT_REPLACE_TOKEN;
				}
				else {
					removeText( $NO_HASH_KEY, $nextArray );
				}
			}
		}
		else {
			foreach my $key ( keys %{$incomingArrayRef} ) {

				# print "$key=";
				removeText( $key, $incomingArrayRef );
			}
		}
	}

	if ( $type eq "ARRAY" ) {
		foreach my $arrayIndex ( @{$incomingArrayRef} ) {  # TBD THIS SHOULD BE FOR LOOP to ensure order.
			my $type = reftype($arrayIndex);
			if ( !defined($type) ) {
				$arrayIndex = $TEXT_REPLACE_TOKEN;
			}
			else {
				removeText( $NO_HASH_KEY, $arrayIndex );
			}

		}
	}
}

#
#my $type = reftype ( $data ); print "Type =$type\n"; #HASH
#	foreach my $element ( keys %{$data} ) {
#		print $element. "\n"; #employee
#    $type = reftype ( $element ); print "Type =$type\n"; #undef
#		foreach my $arrayIndex ( ${$data}{ $element } ){
#			$type = reftype ( $arrayIndex ); print "Type =$type\n"; #ARRAY
#
#			print  ${$arrayIndex}[0];
#			my $length =  @{$arrayIndex};
#			print $length;
#
#			foreach my $test ( @{$arrayIndex} )
#			{
#				$type = reftype ( $test ); print "Type =$type\n"; #HASH
#
#				foreach my $test2 ( keys %{$test} ) {
#					$type = reftype ( $test2 ); print "Type =$type\n"; #udef
#					foreach my $arrayIndex2 ( ${$test}{ $test2  } ){
#						$type = reftype ( $arrayIndex2 ); print "Type =$type\n"; #ARRAY
#						foreach my $test3 ( @{$arrayIndex2} ){
#							$type = reftype ( $test3 ); print "$test2=$test3 Type =$type\n"; #undef
#						}
#					}
#				}
#			}
#
#		}
#	}

sub foo {
	my ($hashKey)          = $_[0];
	my ($incomingArrayRef) = $_[1];

	my $type = reftype($incomingArrayRef);

	# print "Type =$type\n"; #undef

	if ( !defined($type) ) {
		if ( $hashKey ne $NO_HASH_KEY ) {
			foreach my $key ( keys %{$incomingArrayRef} ) {
				foo( $key, $incomingArrayRef );
			}
		}
		else {
			print "=$incomingArrayRef\n";
			return;
		}
	}

	if ( $type eq "HASH" ) {
		if ( $hashKey ne $NO_HASH_KEY ) {
			foreach my $nextArray ( ${$incomingArrayRef}{$hashKey} ) {
				foo( $NO_HASH_KEY, $nextArray );
			}
		}
		else {
			foreach my $key ( keys %{$incomingArrayRef} ) {
				print "$key=";
				foo( $key, $incomingArrayRef );
			}
		}
	}

	if ( $type eq "ARRAY" ) {
		foreach my $arrayIndex ( @{$incomingArrayRef} ) {
			foo( $NO_HASH_KEY, $arrayIndex );
		}
	}
}

