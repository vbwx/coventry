# Coventry - A CLI vocabulary trainer
# Version 1.9
# Copyright (C) 2006, 2012, 2016 Bernhard Waldbrunner

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


$VERSION = 1.9;

$cont = "true";
$save_swapped = "true";

print "Coventry $VERSION, a vocabulary trainer\n(C) Bernhard Waldbrunner\n\n";
until ($fname) {
	print "File name: ";
	chop($fname = <STDIN>);
}
unless (-e $fname) {
	$fname =~ /\.csv$/   or $fname .= ".csv";
}
if (-e $fname) {
	open(FILE, $fname)    or die "Can't open file!\n";

	chop($line = <FILE>)   or warn "File is empty!\n";
	@entry = split(/\t/, $line);
	@test_results = split(/,/ => $entry[2]) if $entry[2];
	@langs = ($entry[0], $entry[1]);
	while ($line = <FILE>) {
		chomp($line);
		@entry = split(/\t/, $line);
		$vocs{$entry[0]} = [
			($entry[1] or ""),    # Translation
			($entry[2] or 0),     # Practice points
			($entry[3] or 0)      # Exam points
		];
	}
	close(FILE);
}

do {
	print "\nMenu:\n"
	    . "\t1   Show all entries / Delete entries\n"
	    . "\t2   Search for entries\n"
	    . "\t3   Look through vocabulary\n"
	    . "\t4   Practice vocabulary\n"
	    . "\t5   Vocabulary exam\n"
	    . "\t--\n"
	    . "\t6   Add entries / Edit right parts of entries\n"
	    . "\t7   Edit left parts of entries\n"
	    . "\t8   Change languages\n"
	    . "\t9   Swap columns\n"
	    . "\t--\n"
	    . "\t0   Quit\n\n";

	$in = <STDIN>;
	chomp($in);
	unless ($in eq "0") { print "-" x 79; print "\n"; }
	if     ($in eq "0") { print "Bye!\n"; $cont = 0; }
	elsif  ($in eq "1") { &show_vocs; }
	elsif  ($in eq "2") { &search_vocs; }
	elsif  ($in eq "3") { &exercise; }
	elsif  ($in eq "4") { &test_vocs; }
	elsif  ($in eq "5") { &examine; }
	elsif  ($in eq "6") { &add_voc; }
	elsif  ($in eq "7") { &change_voc; }
	elsif  ($in eq "8") { &change_langs; }
	elsif  ($in eq "9") { &swap_langs; }
	else {
		$in and warn "Please enter a digit!\n\n";
	}
} while ($cont);

if ($changes) {
	$save_swapped   or &swap_langs(1);
	open(FILE, ">".$fname)    or die "\nCan't write to $fname!\n";
	print FILE $langs[0]."\t".$langs[1];
	print FILE "\t" . join("," => @test_results)   if @test_results;
	print FILE "\n";
	foreach $key (sort { lc $a cmp lc $b } keys %vocs) {
		if ($vocs{$key}[1] || $vocs{$key}[2]) {
			print FILE $key . "\t" . $vocs{$key}[0] . "\t" . ($vocs{$key}[1] || "")
				   . ($vocs{$key}[2] ? "\t".$vocs{$key}[2] : "")
				   . "\n";
		}
		else {
			print FILE $key . "\t" . $vocs{$key}[0] . "\n";
		}
	}
	close(FILE)   and print "\nVocabulary saved.\n";
}
exit;

#-----------------------------------------------------------------------------------------------

# Show all entries
sub show_vocs {
	$i = 0;
	@langs and print "Languages " . $langs[0] . ", " . $langs[1] . "\n\n";
	print "Results\n" . join(" %\n", @test_results) . " %\n" if @test_results;
	<STDIN>  if @test_results;
	foreach $key (sort { lc $a cmp lc $b } keys %vocs) {
		print $key . " = " . $vocs{$key}[0] . "\n";
		$i++;
		if ($i==24) {
			print "Left part of entry to delete: "; chop($in = <STDIN>);
			$i = ($in ? 23 : 0);
			if ($in) {
				if (delete $vocs{$in}) {
					print "Entry deleted.\n";
					$changes = "true";
				}
				else { warn  "\tNo such entry: $in\n"; }
			}
		}
	}
	$in = ".";
	if ($i) {
		while ($in) {
			print "Left part of entry to delete: "; chop($in = <STDIN>);
			if ($in) {
				if (delete $vocs{$in}) {
					print "\tEntry deleted.\n";
					$changes = "true";
				}
				else { warn "\tNo such entry: $in\n"; }
			}
		}
	}
	print "\n"; print '-' x 79; print "\n\n";
}

# Look through entries
sub exercise {
	print "Type [.][Return] to quit.\n\n";
	foreach $key (sort {$vocs{$a}[1]+$vocs{$a}[2] <=> $vocs{$b}[1]+$vocs{$b}[2]} keys %vocs) {
		print $langs[0] . ": " . $key . "\n" . $langs[1] . ": " . $vocs{$key}[0] . "\n";
		chomp($in = <STDIN>);
		if ($in eq ".") { last; }
	}
	print "\n"; print '-' x 79; print "\n\n";
}

# Practice vocabulary
sub test_vocs {
	print "Type [.][Return] to quit.\n\n";
	foreach $key (sort { $vocs{$a}[1] <=> $vocs{$b}[1] } keys %vocs) {
		print $langs[0] . ": " . $key . "\n" . $langs[1] . ": ";
		chop($in = <STDIN>);
		if ($in eq ".") { last; }
		if (lc $in eq lc $vocs{$key}[0]) {
			print "Correct :)\n\n";
			$vocs{$key}[1]++;
		}
		else {
			print "Nope, the answer is: " . $vocs{$key}[0] . "\n\n";
			$vocs{$key}[1] = 0;
		}
	}
	$changes = "true";
	print "\n"; print '-' x 79; print "\n\n";
}

# Vocabulary exam
sub examine {
	print "EXAM\n"; $anz = 0; $sum = 0;
	foreach $key (sort { $vocs{$a}[2] <=> $vocs{$b}[2] } keys %vocs) {
		print "\n" . $langs[0] . ": " . $key . "\n" . $langs[1] . ": ";
		$in = <STDIN>; chomp($in);
		if ($anz==15) { last; }
		if (lc $in eq lc $vocs{$key}[0]) {
			$vocs{$key}[2]++;
			$sum++;
		}
		else { $vocs{$key}[2] = 0; print "!\n"; }
		$anz++;
	}

	if ($anz) {
		print "\n\nResult: $sum (" . int(($sum/$anz)*100) . ' %)';
		push @test_results, int(($sum/$anz)*100);
		$changes = "true";
		<STDIN>;
	}
	print "\n"; print '-' x 79; print "\n\n";
}

# Add/edit translations
sub add_voc {
	$in = "";
	print "Add entries or edit their right parts\n";
	print "Type [.][Return] to quit.\n\n";
	unless ($langs[0] && $langs[1]) {
		print "Define the languages first.\n";
		until ($in) { print "Left: "; chop($in = <STDIN>); $langs[0] = $in; }
		$in = "";
		until ($in) { print "Right: "; chop($in = <STDIN>); $langs[1] = $in; }
		print "\n----\n\n";
		$changes = "true";
	}
	while (1) {
		$in = "";
		until ($in) {
			print $langs[0] . ": ";
			$in = <STDIN>; chomp($in);
		}
		if ($in eq ".") { last; }
		$new = $in; $new =~ s/^\s*|\t|\s*$//g;
		$in = "";
		until ($in) {
			print $langs[1] . ": ";
			$in = <STDIN>; chomp($in); $in =~ s/^\s*|\t|\s*$//g;
		}
		$in or last;
		print "\t".($vocs{$new} ? "Entry changed" : "Entry added").".\n";
		$vocs{$new} = [ $in, 0, 0 ];
		$changes = "true";
	}
	print "\n\n"; print '-' x 79; print "\n\n";
}

# Change language names
sub change_langs {
	print "Type [.][Return] to cancel.\n\n";
	$in = "";
	until ($in) { print "Left: "; chop($in = <STDIN>); }
	if ($in eq ".") {
		print '-' x 79; print "\n\n";
		return;
	}
	$langs[0] = $in; $in = "";
	until ($in) { print "Right: "; chop($in = <STDIN>); }
	if ($in eq ".") {
		$changes = "true";
		print "\nLeft language changed.\n\n";
		print '-' x 79; print "\n\n";
		return;
	}
	$langs[1] = $in; $in = "";
	print "\nLanguages changed.\n\n";
	print '-' x 79; print "\n\n";
	$changes = "true";
}

# Swap languages/columns
sub swap_langs {
	unless (@_) {
		$in = "";
		print "Save changes? (a|y|n) ";
		until ($in) {
			chomp($in = <STDIN>);
			if (lc $in eq "a") {
				print "\n\n", '-' x 79, "\n\n";
				return;
			}
			elsif (lc $in eq "y") { $save_swapped = "true"; $changes = "true"; }
			elsif (lc $in eq "n") { undef $save_swapped; }
			else {
				print "\tPossible actions: A(bort), Y(es), N(o) ";
				undef $in;
			}
		}
	}
	foreach $key (keys %vocs) {
		$vocs_bak{$vocs{$key}[0]} = [ $key, $vocs{$key}[1], $vocs{$key}[2] ];
	}
	%vocs = %vocs_bak;
	undef %vocs_bak;
	($langs[0], $langs[1]) = ($langs[1], $langs[0]);
	print "\nColumns have been ";
	if (@_) { print "restored."; }
	else { print "swapped."; print "\n\n"; print '-' x 79; print "\n\n"; }
}

# Change left columns
sub change_voc {
	print "Edit left parts of entries\n";
	print "Type [.][Return] to quit.\n\n";
	$in = "";
	while (1) {
		print "Current: "; chomp($in = <STDIN>);
		$in =~ s/^\s*|\t|\s*$//;
		last if $in eq ".";
		print "New: "; chomp($new = <STDIN>);
		$new =~ s/^\s*|\t|\s*$//;
		last if $new eq ".";
		if ($vocs{$in}) {
			if ($vocs{$new}) {
				print "An existing entry would be overwritten; hit [Return] to confirm.";
				substr(<STDIN>, 0, -1) eq "" or next;
			}
			$vocs{$new} = [ $vocs{$in}[0], 0, 0 ];
			delete $vocs{$in}; $changes = "true";
			print "\tEntry changed.\n";
		}
		else { print "\tNo such entry: $in\n"; }
		print "\n";
	}
	print "\n", '-' x 79, "\n\n";
}

# Search for entries
sub search_vocs {
	print "Hit [Return] to quit.\n";
	while (1) {
		print "\nSearch: ";
		chomp($in = <STDIN>);
		$in or last;
		foreach $key (sort keys %vocs) {
			if ((lc $key eq lc $in) || (lc $vocs{$key}[0] eq lc $in)) {
				print "\t$key = ".$vocs{$key}[0]."\n";
			}
		}
	}
	print "\n", '-' x 79, "\n\n";
}
