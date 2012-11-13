#!/usr/bin/perl

#USAGE: perl getAllFlickrPhotos.pl COOKIE_FILE FLICKR_START_PAGE START_INDEX_NUMBER
#Ex: perl getAllFlickrPhotos.pl myCookieFile.txt 'http://www.flickr.com/photos/premj/page3' 2>/dev/null > ./meta.txt

my $double_quotes='"';
my $colon=':';
my $ctrlM = '';
my $ctrlA = '';
my $ctrlB = '';
my $delimiter = $ctrlA;

my $cookieFile = $ARGV[0];
my $startPage = $ARGV[1];
my $startNumber = $ARGV[2];
#print "cookieFile=$cookieFile\n";
#print "startPage=$startPage\n";

my $count = 0;
my $url = $startPage;
while(true){
    ++$count;
    print "URL: $url\n";
    my @outArr = ();
    getCurlFile($url, $cookieFile, \@outArr, 0, '1.txt', true);
    getAllPicturesInPage(\@outArr);
    #print "\n=================\n";
    $url = getNextPageUrl(\@outArr);
    if($url eq ''){last;}
    #if($count == 100){last;}
    #last;
}

sub getAllPicturesInPage
{
    my $outArr = shift;
    foreach my $l(@$outArr){
	if(
	    $l =~ 'data-photo-media="photo"'
	    ){
	    #print $l;
	    my @a1 = split /href=$double_quotes/, $l;
	    my @a2=split/$double_quotes/, $a1[1];
	    my @aa2 = split /\//, $a2[0];
	    my $photoPageUrl = 'http://www.flickr.com';
	    my $locCount = 0;
	    foreach my $i(@aa2){
		++$locCount;
		if($locCount >= 2 && $locCount <= 4){
		    $photoPageUrl .= '/'.$i;
		}
	    }
	    my $originalPhotoPageUrl = $photoPageUrl.'/sizes/in/photostream/';
	    my $lightboxPhotoPageUrl = $photoPageUrl.'/lightbox/';
	    my $fullDetailsPhotoPageUrl = $photoPageUrl.'/in/photostream/';


            my @a3 = split /alt=$double_quotes/, $l;
            my @a4=split/$double_quotes/, $a3[1];
	    my $photoTitle = $a4[0];


	    my $originalPhotoPageUrl1 = '';
	    my @a4=split/\//, $originalPhotoPageUrl;
	    foreach my $i(@a4){
		if($i eq 'sizes'){$i = 'sizes/o'}
		$originalPhotoPageUrl1 .= ($originalPhotoPageUrl1 eq '')? $i : '/'.$i;
	    }

	    my $originalFileUrl = '';
	    my @outArr1 = ();
	    getCurlFile($originalPhotoPageUrl1, $cookieFile, \@outArr1, 0, '1.txt', true);
	    for(my $i=0; $i<@outArr1 ;++$i){
		my $curLine = $outArr1[$i];
		if($curLine =~ 'Download the Original'){
# && $i =~'a href'){
		    my @a5 = split /$double_quotes/, $outArr1[$i-1];
		    $originalFileUrl = $a5[1];
		    last;
		}
	    }

	    my $tags = getTags($fullDetailsPhotoPageUrl);

	    #print "originalPhotoPageUrl:$originalFileUrl${delimiter}lightboxPhotoPageUrl:$lightboxPhotoPageUrl${delimiter}fullDetailsPhotoPageUrl:$fullDetailsPhotoPageUrl${delimiter}photoTitle:$photoTitle${delimiter}$tags\n===\n";

	    my $localFileName = getLocalFileName('image');
	    my @outArr6 = ();
            getCurlFile($originalFileUrl, $cookieFile, \@outArr6, 0, $localFileName, false);

	    print "$localFileName${delimiter}$originalFileUrl${delimiter}${delimiter}$photoTitle${delimiter}$tags\n===\n";
	}
	elsif($l =~ 'data-photo-media="video"'){
            my @a1 = split /href=$double_quotes/, $l;
            my @a2 = split/$double_quotes/, $a1[1];
	    my $videoUrl = $a2[0];
	    #print "videoUrl=$videoUrl\n";
            my $videoPageUrl = 'http://www.flickr.com'.$videoUrl;
	    my $tags = getTags($videoPageUrl);
	    my $videoPageUrl1 = '';
	    my @outArr2 = ();
            getCurlFile($videoPageUrl, $cookieFile, \@outArr2, 0, '1.txt', true);
	    for(my $i=0; $i<@outArr2 ;++$i){
                my $curLine = $outArr2[$i];
		if($curLine =~ 'video_download.gne'){
		    my @a3 = split /href=$double_quotes/, $curLine;
		    my @a4 = split/$double_quotes/, $a3[2];
		    $videoPageUrl =  'http://www.flickr.com'.$a4[0];
		    my @outArr3 = ();
		    getCurlFile($videoPageUrl, $cookieFile, \@outArr3, 1, '1.txt', true);
		    $videoPageUrl1 = getRedirectUrl($videoPageUrl, $cookieFile);
		    last;
		}
	    }
            my @a3 = split /alt=$double_quotes/, $l;
            my @a4=split/$double_quotes/, $a3[1];
            my $videoTitle = $a4[0];
	    #print "videoPageUrl:$videoPageUrl1${delimiter}videoTitle:$videoTitle\n===\n";

	    my $localFileName = getLocalFileName('video');
	    my @outArr6 = ();
            getCurlFile($videoPageUrl1, $cookieFile, \@outArr6, 0, $localFileName, false);

	    print "$localFileName${delimiter}$videoPageUrl1${delimiter}$videoTitle${delimiter}$tags\n===\n";
	}
    }
}

sub getLocalFileName
{
    my $type = shift;

    my $ext = ($type eq 'image')? 'jpg':'flv';
    my $num = sprintf("%05d", $startNumber);
    ++$startNumber;
    return "${num}_${type}.${ext}";
}

sub getNextPageUrl
{
    my $outArr = shift;
    my $retVal;
    foreach my $l(@$outArr){
	if($l =~ 'Next rapidnofollow'){
	    #print "XXX:$l";
            #<a data-track="next" href="/photos/premj/page2/" class="Next rapidnofollow">next &rarr;</a>
	    my @a1 = split /$double_quotes/, $l;
	    $retVal = 'http://www.flickr.com/'.$a1[3];
	    last;
	}
    }
    return $retVal;
}

sub getCurlFile
{
    my $url = shift;
    my $cookieFile = shift;
    my $outArr = shift;
    my $withStdErr = shift;
    my $outFile = shift;
    my $retArr = shift;

    #my $outFile = '1.txt';
    my $c = 'curl -b '.$cookieFile." '".$url."'".' -o '.$outFile;
    if($withStdErr == 1){
	$c = 'curl -v -b '.$cookieFile." '".$url."'".' 2>&1 '." > $outFile";
    }

    print "Executing: $c\n";
    `$c`;

    if($retArr){
	open FH, $outFile;
	@$outArr = ();
	while(my $l=<FH>){
	    chomp($l);
	    push @$outArr, $l;
	}
    }
}

sub getRedirectUrl
{
    my $url = shift;
    my $cookieFile = shift;
    my $c = 'curl -v -b '.$cookieFile.' '.$url.' 2>&1 '."|grep location";
    my $res = `$c`;
    my @a1 = split /location$colon /, $res;
    my @a2=split /$ctrlM/, $a1[1];
    return $a2[0];
}


sub getTags
{
    my $url = shift;

    my %h = ();

    my @outArr = ();
    getCurlFile($url, $cookieFile, \@outArr, 0, '1.txt', true);

    my $sets = '';
    my $startCapture = 0;
    foreach my $i(@outArr){
	if($i =~ 'This photo also appears in'){
	    $startCapture = 1;
	}
	else{
	    if($startCapture == 1){
		if($i =~ 'class="context-title"'){
		    my @a1 = split /title=$double_quotes/, $i;
		    my @a2 = split /$double_quotes/, $a1[1];
		    $sets = $a2[0];
		}
	    }
	}
    }

    foreach my $i(@outArr){
	if($i =~ 'data-tag='){
	    my @a1 = split /data-tag=$double_quotes/, $i;
	    for(my $i=0;$i<@a1;++$i){
		if($i > 0){
		    my @a2 = split /$double_quotes/, $a1[$i];
		    $h{$a2[0]} = 1;
		}
	    }
	}
    }

    my $tags = '';
    foreach my $i(keys(%h)){
	$tags .= ($tags eq '')? $i : $ctrlB.$i;
    }
    return "$tags${delimiter}$sets";
}
