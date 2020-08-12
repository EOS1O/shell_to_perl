#!/usr/bin/perl -w

# read the file
$file_name = shift @ARGV;

open my $in, '<', "$file_name" or die "Can' t open file '$file_name'! $!";
@file_lines = <$in>;
close $in;

# use flag to judge wether if,for,while in a function
our $flag = 0;
our $flag_while = 0;


sub equal_match {
    my ($line) = @_;
    #               a=$1
    # $a = $ARGV[0]
    if ($line =~ /(.*)=\$(\d+)/){
        my $param = $2;
        $param--;
        print "\$$1 = \$ARGV[$param];\n";
    }elsif($line =~ /(.*)=\$(\w+)/){
		print "\$$1 = \$$2;\n";
	}elsif ($line =~ /(\s*)(.*)=\`expr (.*)\`(.*)/){
        print("$1\$$2 = $3;$4\n");
    }elsif ($line =~ /(.*)=(.*)/){
        print "\$$1 = \'$2\';\n";
    }
}

sub echo_match {
    my ($line) = @_;
    #               a=$1
    # $a = $ARGV[0]
    #print($line);
    if ($line =~ /(\s*)echo\s*(.*)/){
        print "$1";
        if ($2 =~ /(.*)\$(\d).*/){
            $num = $2-1;
			#print("here\n");
			#print("\n");
            print("print \"$1\$ARGV\[$num\]\\n\";\n");
			print "\n";
        }elsif($2 =~ /^[\'](.*)[\']$/){
			$print = $1;
			$print =~ s/\"/\\\"/g;
			if($print =~ /(.*)\"(.*)/){
				print("print \"$1\\\"$2\\n\";\n");
			}else{
            	print "print \"$1\\n\";\n";
			}
        }elsif($2 =~ /^[\"](.*)[\"]$/){
            print "print \"$1\\n\";\n";
        }else{
            #print("here");
            print "print \"$2\\n\";\n";
        }    
    }
}

sub if_match {
    my ($lines) = @_;
    #               a=$1
    # $a = $ARGV[0]
    
    while (@$lines){
        my $if_line = shift @$lines;
        #print("if_line here $if_line\n");
        #$flag = 0; 
        
        if ($if_line =~ /^[i]f\s*test\s*(.*)\s*=\s*(.*)/){
            # print "$1";
            print "if (\'$1\' eq \'$2\') {\n";
            next;
        }elsif ($if_line =~ /^[i]f\s*\[\s*\-d\s*(.*[^\s*])\s*\]/){
			#$1 =~ s/^[\s]+//;
			#$1 =~ s/[\s]+$//;
            print("if \(\-d \'$1\'\) \{\n");
        }elsif ($if_line =~ /^[i]f\s*test\s*\-d\s*(.*)\s*/){
            print("if \(\-d \'$1\'\) \{\n");
        }elsif($if_line =~ /^[i]f\s*test\s*\-r\s*(.*)/){
            print("if \(\-r \'$1\' \) \{\n");
        }elsif ($if_line =~ /(\s*)else/){
            if($flag eq 1){
                print "    } else {\n";
            }else{
                print "} else {\n";
            }
            next;
        }elsif ($if_line =~ /^[e]lif\s*test\s*(.*)\s*=\s*(.*)/){
            print("    } elsif \(\'$1\' eq \'$2\'\) \{\n");
            $flag = 1;
        }elsif ($if_line =~ /(\s*)fi/){
            if($flag eq 1){
                print("    }\n")
            }else{
                print "}\n"; 
            }
            last;
        }elsif ($if_line =~ /then/){
            next;
        }else {
            unshift @$lines, $if_line;
            check_every_line($lines);
        }
    }
}

sub for_match {
    my ($lines) = @_;
    #               a=$1
    # $a = $ARGV[0]
    while (@$lines){
        my $for_line = shift @$lines;
        if ($for_line =~/\s*for (.*) in (.*)\n/){
            my @words =split(/ /, $2);
            if($2 =~ /\*\.c/){
                print "foreach \$$1 (";
                print("glob\(\"*.c\"\)");
                print "){\n";
            }else{
                print "foreach \$$1 (\'";
                print join("\',\'",@words);
                print "\'){\n";
            }
            
            next;
        } elsif ($for_line =~ /(\s*)done/){
            print "}\n";
            last;
        }
        elsif ($for_line =~ /(\s*)do/){
            next;
        }elsif ($for_line =~ /(\s*)exit(.*)/){
            print("$1exit$2;\n")
        }elsif ($for_line =~ /(\s*)read\s(.*)/){
            print("$1\$$2 = <STDIN>;\n");
            print("$1chomp \$$2;\n");
        }
        else {
            unshift @$lines, $for_line;
            check_every_line($lines);
        }
    }
}

sub while_match {
    my ($lines) = @_;
    while (@$lines){
        my $while_line = shift @$lines;
        #print("here\n");
        #if ($flag_while eq 1){
           #print("    ");
        #}
        if ($while_line =~ /(\s*)while (.*)\n/){
            $space = $1;
			@newspace = ();
			my $len = length($space);
			my $new_len = $len -1;
			for($i=0;$i<$new_len;$i++){
				push(@newspace," ");
			}
			$new_space = join("",@newspace);
            my @words =split(/ /, $2);
            #print("here\n");
            if($2 =~ /test\s*\$(\w*)\s*\-le\s*\$(\w*)/){
                print("$new_space while \(\$$1 \<\= \$$2\) \{\n");
                next;
            }elsif($2 =~ /test\s*\$(\w*)\s*\-lt\s*\$(\w*)/){
                print("$new_space while \(\$$1 \< \$$2\) \{\n");
                next;
            }elsif($2 =~ /test\s*\$(\w+)\s+\-lt\s+(\d+)/){
                print("$new_space while \(\$$1 < $2\) \{\n");
                next;
            }      
        }elsif ($while_line =~ /(\s*)(\w+)=\$\(\((.*)\)\)(.*)/){
            print("$1\$$2 = \$$3;$4\n");  
            #print("here");  
        }elsif ($while_line =~ /(\s*)test \$\(\((\w+) \% (\w+)\)\) \-eq (\d+) \&\& return (\d+)/){
                print("$1\$$2 \% \$$3 == $4 and return $5;\n");
        }
        elsif ($while_line =~ /(\s*)test \$\(\((\w+) \% (\w+)\)\) \-eq (\d+)/){
                print("$1\$$2 \% \$$3 == $4;\n");
        }elsif ($while_line =~ /(\s*)done/){
            print("$1}\n");
            last;
        }elsif ($while_line =~ /(\s*)do/){
            #print("here_do");
            next;
        }
        else {
            unshift @$lines, $while_line;
            check_every_line($lines);
        }
    }
}

sub function_match {
    my ($lines) = @_;
    while (@$lines){
        my $function_line = shift @$lines;
        if($function_line =~ /(\s*)(.*)\(\) \{/){
            print("$1sub $2 {\n");
        }elsif ($function_line =~ /(\s*)local (.*)/){
            my @words =split(/ /, $2);
            #$para = join("\$",@words);
            #$para1 = "\$";
            #$para1 .= $para;
            #@para =split(/\$/, $para1);
            #$para2 = join(",",@words);
            #print("$para2\n");
            my @newwords = ();
            foreach $word (@words){
                $temp = "\$";
                $temp .= $word;
                push(@newwords,$temp);
            } 
            $para = join(",",@newwords);
            #print("para: $para\n");
            print("$1my \($para\);\n");
        }elsif($function_line =~ /(\s*)(\w+)=\$(\w+)/){
            my $num = $3 -1;
            print("$1\$$2 = \$\_\[$num\];\n");
        }elsif($function_line =~ /(\s*)(\w+)=(\d+)/){
            print("$1\$$2 = $3;\n");
        }elsif($function_line =~ /(\s*)while(.*)/){
            $flag_while = 1;
            unshift @$lines, $function_line;
            while_match($lines);
        }elsif($function_line =~ /(\s*)\}/){
            print("$1\}\n");
        }
        else{
            unshift @$lines, $function_line;
            check_every_line($lines); 
        }
    }
}

sub ls_match{
    my ($line) = @_;
    if ($line =~ /ls(.*)/){
        print("system \"ls $1\";\n");
    }
}

sub pwd_match{
    my ($line) = @_;
    if($line =~ /pwd/){
        print("system \"pwd\";\n")
    }
}

sub id_match{
    my ($line) = @_;
    if($line =~ /id/){
        print("system \"id\";\n")
    }
}

sub date_match{
    my ($line) = @_;
    if($line =~ /date/){
        print("system \"date\";\n")
    }
}

sub cd_match{
    my ($line) = @_;
    if ($line =~ /cd\s(.*)/){
        print("chdir \'$1\';\n");
    }
}

sub note_match{
    my ($line) = @_;
    if ($line =~ /^[\#][^!](.*)/){
        print("\# $1\n");
    }
}

sub null_match{
    my ($line) = @_;
    if ($line =~ /(\s*)/){
        print("\n");
    }
}

sub exit_match{
    my ($line) = @_;
    if ($line =~ /^[e]xit(.*)/){
        print("exit$1;\n");
    }
}

sub return_match{
    my ($line) = @_;
    if ($line =~ /(\s*)return (\d+)/){
        print("$1return $2;\n");
    }
}

sub use_function_match{
    my ($line) = @_;
    if ($line =~ /(\s*)(\w+\_\w+)\s*\$(\w+) \&\& (\w+) \$(\w+)/){
        print("$1$2 \$$3 or print \"\$$5\\n\";\n");
    }
}

sub check_every_line {
    my ($lines) = @_;
    my $line = shift @$lines;
    #  a=hello
    #print("$flag\n");
    #print("line here $line\n");
    
    if ($flag eq 1){
        print("    ");
    }
    if ($line =~ /(\s*)^[i]f\s*(.*)/){
        unshift @$lines, $line;
        if_match($lines);
    }elsif ($line =~ /for\s*(.*)/){
        unshift @$lines, $line;
        for_match($lines);
    }elsif ($line =~ /(.*)=(.*)/){
        equal_match($line);
    }elsif ($line =~ /(\s*)(\w+\_\w+)\s*\$(\w+)\s*\&\&\s*(\w+)\s*\$(\w+)/){
        #print("use_here\n");
        use_function_match($line);
    }elsif ($line =~ /\s*echo\s*(.*)/){
        echo_match($line);
    }elsif ($line =~ /ls(.*)/){
        ls_match($line);
    }elsif ($line =~ /pwd/){
        pwd_match($line);
    }elsif ($line =~ /id/){
        id_match($line);
    }elsif ($line =~ /date/){
        date_match($line);
    }elsif ($line =~ /cd\s(.*)/){
        cd_match($line);
    }elsif ($line =~ /^[\#](.*)/){
        note_match($line);
    }elsif ($line =~ /^[e]xit(.*)/){
        exit_match($line);
    }elsif ($line =~ /while (.*)\n/){
        unshift @$lines, $line;
        while_match($lines);
        #print("here");
    }elsif ($line =~ /(\s*)(.*)\(\) \{/){
        unshift @$lines, $line;
        function_match($lines);
    }elsif ($line =~ /(\s*)return(.*)/){
        return_match($line);
    }

    elsif ($line =~ /(\s*)/){
        null_match($line);
        #print("yeah\n");
    }

}

print "#!/usr/bin/perl -w\n";


while (@file_lines) {
    # check every line
	# \@ means to use the address of this array
    check_every_line(\@file_lines);
}



