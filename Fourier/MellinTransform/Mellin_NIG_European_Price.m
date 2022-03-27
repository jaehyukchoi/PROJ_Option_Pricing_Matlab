function [ price ] = Mellin_NIG_European_Price( S_0, W, T, r, q, call, alpha, beta, delta, N1, tol)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% About: Pricing Function for European Options using Mellin Transform
% Models Supported: Normal Inverse Gaussian (NIG)
% Returns: price of contract
% Author: Justin Lars Kirkby/ Jean-Philippe Aguilar
%
% Reference: 1) "Closed-form option pricing in exponential Levy models", Aguilar and Kirkby, 2021
%            2) "Pricing, risk and volatility in subordinated marketmodels", Aguilar, Kirkby, Korbel, 2020
%
% ----------------------
% Contract/Model Params 
% ----------------------
% S_0 = initial stock price (e.g. 100)
% W   = strike  (e.g. 100)
% r   = interest rate (e.g. 0.05)
% q   = dividend yield (e.g. 0.05)
% T   = time remaining until maturity (in years, e.g. T=1)
% call  = 1 for call (else put)
%
% alpha = param in model
% beta = param in model
% delta = param in model
%
% ----------------------
% Numerical Params 
% ----------------------
% N1  = maximum number summation terms in the series, will sum fewer terms
%       if error threshold (tol) is reached
% tol = desired error threshold of price (will stop adding terms once satisfied) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 11
    tol = 0;
end

N2 = N1;
N3 = N1;

gam = sqrt(alpha^2 - beta^2);
k0 = log(S_0/W) + (r - q + delta*(sqrt(alpha^2 - (beta + 1)^2) - gam))*T;
adt = alpha*delta*T;
dta = 0.5*delta*T/alpha;

sum = 0;
last = 0;
cons =  W*alpha*exp((gam*delta - r)*T)/sqrt(pi);
tol = tol/cons;

facts = getFacts();

if beta == 0
    % Symmetric Formula
    for n1 = 0:N1
        fn1 = facts(n1 + 1);
        for n2 = 1:N2
            d = n1 - n2;
            term = k0^n1 / (fn1 * gamma(1 - d/2) );
            term = term * besselk((d + 1)/2, adt) * (dta)^((1 - d)/2);
            sum = sum + term;
        end
        if n1 > 1 && abs(sum - last) < tol
            break;
        end
        last = sum;
    end
else
   % Asymmetric Formula
    for n1 = 0:N1
        fn1 = facts(n1 + 1);
        for n2 = 0:N2
            fn2 = facts(n2 + 1);
            for n3 = 1:N3
                g = pochhammer(-n1 + n3 + 1, n2, facts);
                term = g * k0^n1 * beta^n2 / (fn1 * fn2 * gamma(1 + (-n1 + n2 + n3)/2) );
                term = term * besselk((n1 - n2 - n3 + 1)/2, adt) * (dta)^((-n1 + n2 + n3 + 1)/2);
                sum = sum + term;
            end
        end
        if n1 > 1 && abs(sum - last) < tol
            break;
        end
        last = sum;
    end
end


price = cons*sum;

if call ~= 1  % price put using put-call parity
    price = price - (S_0*exp(-q*T) - W*exp(-r*T));
end

end

function p = pochhammer(a, n, facts)
if (a == 0 && n <= 0) || (n == 0 && a > 0)
    p = 1;
elseif a == 0 && n > 0
    p = 0;
elseif a > 0
    if n == 1
        p = a;  % uses Gamma(a + 1) = a * Gamma(a)
    elseif n > 0
        p = prod(a:a + n - 1);
        % p = gamma(a + n)/gamma(a); 
    else
        p = inf; % TODO: what happens when a - n < 0
    end
else  
    p = neg_poch(a, n, facts);
end
    
end

function p = neg_poch(m, n, facts)
% Used for (-m)_n, m >= 1

m = -m;

if n > m
    p = 0;
else
    p = (-1)^n * facts(m + 1) / facts(m - n + 1);
end

end


function facts = getFacts()
facts = [
1 
1 
2 
6 
24 
120 
720 
5040 
40320 
362880 
3628800 
39916800 
479001600 
6227020800 
87178291200 
1307674368000 
20922789888000 
355687428096000 
6402373705728000 
121645100408832000 
2432902008176640000 
51090942171709440000 
1124000727777607680000 
25852016738884978212864 
620448401733239409999872 
15511210043330986055303168 
403291461126605650322784256 
10888869450418351940239884288 
304888344611713836734530715648 
8841761993739700772720181510144 
265252859812191032188804700045312 
8222838654177922430198509928972288 
263130836933693517766352317727113216 
8683317618811885938715673895318323200 
295232799039604119555149671006000381952 
10333147966386144222209170348167175077888 
371993326789901177492420297158468206329856 
13763753091226343102992036262845720547033088 
523022617466601037913697377988137380787257344 
20397882081197441587828472941238084160318341120 
815915283247897683795548521301193790359984930816 
33452526613163802763987613764361857922667238129664 
1405006117752879788779635797590784832178972610527232 
60415263063373834074440829285578945930237590418489344 
2658271574788448529134213028096241889243150262529425408 
119622220865480188574992723157469373503186265858579103744 
5502622159812088456668950435842974564586819473162983440384 
258623241511168177673491006652997026552325199826237836492800 
12413915592536072528327568319343857274511609591659416151654400 
608281864034267522488601608116731623168777542102418391010639872 
30414093201713375576366966406747986832057064836514787179557289984 
1551118753287382189470754582685817365323346291853046617899802820608 
80658175170943876845634591553351679477960544579306048386139594686464 
4274883284060025484791254765342395718256495012315011061486797910441984 
230843697339241379243718839060267085502544784965628964557765331531071488 
12696403353658276446882823840816011312245221598828319560272916152712167424 
710998587804863481025438135085696633485732409534385895375283304551881375744 
40526919504877220527556156789809444757511993541235911846782577699372834750464 
2350561331282878906297796280456247634956966273955390268712005058924708557225984 
138683118545689864933221185143853352853533809868133429504739525869642019130834944 
8320987112741391580056396102959641077457945541076708813599085350531187384917164032 
507580213877224835833540161373088490724281389843871724559898414118829028410677788672 
31469973260387939390320343330721249710233204778005956144519390914718240063804258910208 
1982608315404440084965732774767545707658109829136018902789196017241837351744329178152960 
126886932185884165437806897585122925290119029064705209778508545103477590511637067401789440 
8247650592082471516735380327295020523842257210146637473076098881993433291790288339528056832 
544344939077443069445496060275635856761283034568718387417404234993819829995466026946857533440 
36471110918188683221214362054827498508015278133658067038296405766134083781086959639263732301824 
2480035542436830547970901153987107983847555399761061789915503815309070879417337773547217359994880 
171122452428141297375735434272073448876652721480628511030304905066123383956194496253690059725733888 
11978571669969890269925854460558840225267029209529303278944419871214396524861374498691473966836482048 
850478588567862176139364498862283450363106657876759119884137546969850291984346623845721803156845756416 
61234458376886076682034243918084408426143679367126656631657903381829221022872956916891969827292894461952 
4470115461512683367030518111879159855011125453675376127499372976904192242294440576507107183576895048384512 
330788544151938558975078458606627397928594841525087028177611631961228972749086355889619432768006702663467008 
24809140811395391401649674453868616759922516881580717884144963618612492793329521656999844718186305916810297344 
1885494701666049846649767567286674986020753759697889931196791720482648043560619012598537844549685032003930423296 
145183092028285837925033723190960213624220326225543510376814897182582303110787462992309948307745678711432381726720 
11324281178206294606285193764734547659641544873910049469239570110699644621282776159978832493218689331409071173009408 
894618213078297291394536105678124660091699861979864830895281485890971416487504167917951760559283842969422038852173824 
71569457046263778832073404098641551692451427821500630228331524401978643519022131505852398484420816675798776564959674368 
5797126020747365547859207609316955153302418317114924299299934140244381749043408420663995193999459259329102516576025837568 
475364333701283981804950871934204857403260987909684614932289567004882674634326008655216234173410083475042065689611178344448 
39455239697206569095363763848575524105091557652834963035068520647090338762195044371133838774594273621857211161281310377377792 
3314240134565351991893962785187002255986138585985099085000359647021178112607661449751964466234594461331925608329126314254532608 
281710411438054936145340070063731769270618697594701234453923080571636972801512907171791271651453851961008097129997800044545179648 
24227095383672724277628115968482030522825707406365319023898287641277303090920578351271773357158562842391230015963508220979549569024 
2107757298379526908723379823722428723253356281476796516744835439819327865545820130415624631892617112325588092315921658107822337949696 
185482642257398355359015441641340379717002520724001675848028952155157918424578282117944000727442910232086550560628100855367408841392128 
16507955160908452497218052643056785820348586593118454131228292379023767876373998621963681432374396360185860939835599722920061648806871040 
1485715964481760688598126444658390468648504385338494631194665214503009929244428884407664620677918947601692538663274334960161140774153486336 
135200152767840228116141248983464474000315190336164090023053168975093962659595589494945258181259227289565007146009064474002163016890673266688 
12438414054641300055918190849808704283732243800785472203727097932000687811897290487171609691949473988773572358313712866199772466321053448142848 
1156772507081640872708168771053910362702557453046286765300873130615713476227390429979366250504125810956242157790289615727775585913909863306493952 
108736615665674240994816729183762001752135081532694567149618171011945851076444857687577437120278217589896360543234882091889200965381187714945122304 
10329978488239052206885505130495304991006115078121225426977331552932345209983325487893772190631276157126501537780698430576453773283127019334195478528 
991677934870949102715849029478410597802063033500204435194993914996262675344674144417713144475342926858025486847392744430654763018452435547907969515520 
96192759682482062236598631563798937437476306361515295860273049067319419226943192827878886900710340579037421510433530649010990406523708314612471414390784 
9426890448883242029410148360874034376137592466180063696357188182614769297217373775790759257383412737431326439501183709769874985637770333212700442263289856 
933262154439440960911604687726529403237621654151826305939361630078862160424520003803285166480957861005701317510617187267217623578139262988057343784065695744 
93326215443944102188325606108575267240944254854960571509166910400407995064242937148632694030450512898042989296944474898258737204311236641477561877016501813248 
9425947759838353638138390835342801376610975723095888339920014242478768251047951733961834230251772401385381873852523273511991274827736142409989069734354272387072 
961446671503512108551098468996872516993486281273776279655019164712488171916774592368567957322868226384982187894861027816146283489308561271194593264363559458963456 
99029007164861753574104173353829959119840213587603550977595970143247198666981236326723820707135417324040064427202242800388622136039545500810497297411854931555516416 
10299016745145621553359182054762848245165958006210981247509469384131511290543206553945828252373444680882643618952993963518745670258094979779977582459484649549641809920 
1081396758240290348210869921049787686085357708169730988621187482453493212072612258663790673020750118457699980463572452092522082693661819116546316351266107589254107365376 
114628056373470783195262178791869885150372134974981857049798601542754676287616326162938700437174657932394775194874661651509774290443489164051042101334162066851708352331776 
12265202031961373185133888353370611130684668524854136840277622617824654987491120488233295563394527465880023230174031122970080372499095001280782895493213123617184939419631616 
1324641819451828358912841223208903721969150593335392516905465643871506013804748686213541388027857383295519634150431801099139171361749124435300456711000167851248199786240671744 
144385958320249281895211638114231048758962740708165300332574711789391685278558717651905972808586720726491483073402144430319927168280381361555797909879849011686559753441596407808 
15882455415227421289655392351515189289144558208272049215939288190702874949438682229949505800912531174854106019567414459205248903105897894971654398555177121848553771682648345804800 
1762952551090243665975210588885144142387414195100989311383803233846619844411373359108703401397152961517526948327940490533490958560703331680555091440947787242605540750086427113422848 
197450685722107283218203224975563190350604098858598125302874203564961210901795886052940088784315404959246758100114554585320567376838138578357747136064291560700269291680195376450633728 
22311927486598122561395742763464263293811085711458827504898079485289004131566259313948148502297697156551908058556057846875398914665071585162560040055953309730837353620093009923758096384 
2543559733472186205984785013970489854470847792378977572407496727142253030323344177018786997575166305186774479690234182114834728179176544494308091621715820528124381901517757837570933260288 
292509369349301414171317466983763626351066482490080838864228039834663473319338986788600397507339178163503285987117253188513945744543074764016065369127692817702167502857927244907779926786048 
33931086844518965033194432062534716898733796047438137448775849025668322561295546839066546536978813348231985419477781328258303410431554030031323720045817206723636050739092232075729560101978112 
3969937160808719035516914105546083316129144899609623379494025075823655775671863699734165199370837152945139637435339450080229269140755163261563772810417232690049049348643093126163025872065396736 
468452584975428833021146646814567601649600858899761983789620882005863329785250305734040051053149920962518753508300395503370245666101721723083039844863345029073890156274277583663759649529785221120 
55745857612076033333946596938961053806019179795001037546326945837492339367137742780510072138432293369384101420636637780506186496519649138194305750351243690774695184219682241207240231351096375771136 
6689502913449123933681342530579439120523775756341546089360093784620090324126011858610763674005344861930779387322735825049576193801545269664994272835560837966773424760538449951889918907707412713570304 
809429852527344001286822374367783120479258932042013350108502525209350161213688816895938003163169155685249328518343891519892014312451987782930100389629933788074784183691025963616992896186529128659288064 
98750442008335975771386594694042667512406118845315870110284243810270370655301200902289870551084388902234050553564994114624253260948981065526033632124062906320002086008101445028038232030953741735287586816 
12146304367025324845837253661169005205421689094860932220203889171869434996608192505473415582579316934206019475818161948117127665043471218350935019389220629267648749936761134253494071712465660221123700195328 
1506141741511140361082970935625106973149134079213189040694064611290402469291784349376899830829867484515795051439621218300470678438729622083715830084690979092223507252900426925300358777584774193094861734805504 
188267717688892538291710440519845543681884351351211642746915315538460412792684266823199728040717355805605164453895552619595370444449591794431421678523215389148946427029232083284552835657699349012546428480782336 
23721732428800459167764066567904427019588717049410716201486424714053382008474495042227541655080843174654805891489358061944524097403053913359185651615862067284384019765684399385566424184991965163646966305067630592 
3012660018457658234883070182556687865382251753244489573847454084501848243553677518772315679426611138886230128806347146520349235313056404532147605965510857871534442256517614132876212580230487324740490782114710552576 
385620482362580254065032983367256046768928224415294665452474122816236575174870722402856406966606225777437456487212434754604702120071219780114893563585389807556408608834254609008155210269502377566782820110682950729728 
49745042224772854994195754995984321775186454084690957642505438343827531881449744562988642485879033169319782753375155346294398792685964119093522997953845956522259835078533620164534957519928786364433332294535208318795776 
6466855489220471639133779215212205525559279171173784945748885246884175267930021854820560154819298873452752638826991163393530815561567449679940440106707432852165916389487114202627157806178434289901761832829076706196193280 
847158069087881742086644741231290352654175677623894710131598531401105633523183910417040911862074814594470211813825089317169995871086726288297213173538216515421888170362477159233235808489102174854917491750291001173222621184 
111824865119600391881756405725967890237237132883901220469184898780385589437419005326196429527322496905986621772018338752872897776337775645819184378964589940067847967974619757219186420346700866301429098370629250999333129551872 
14872707060906851873704731576473721249631137913552831124729413280455008731194810377037305394458228551918101807666480402867268739119570205596165635674924655944907462366317512868500684321965374677855831432466063010819435055284224 
1992942746161518119515618621957237604004633183135307377411702562641928012990419172110605997074917693275026424561777666622316197904953101271769601679337080717850711333175261624647749672372692617682698864644516139822044786993397760 
269047270731804954550825956441624688126209292331472360831123530473738456950956033144903256480443203973995025359981506957185436887053817012519987827004592077914349663021669679255804079575824860493826359341926026510045249021358899200 
36590428819525472095270997856689926732436898934919679945497453555330819864933334190144690561272831950257072841517301248119440181846840733500510784732395672726629210123738759465461662266943455091716004686967071609908781138123969003520 
5012888748274989842521694599426138924205701377011410020776544409633692908413948670535789229620852581045019037602127906005910111453095104988981903243400176751041546815484208470447706215886651037367753139733836138121410797885944517099520 
691778647261948586971938019887937183743951421209063129461747481123139522627517193083163592242883656560716943208173663145224133387391138175986315184075660601137521106589036343198599091861493360866221643312455276165725252192922221896794112 
96157231969410858830469292126874942877955258679849089375295760272644279457618873519719488472145244087241652473083013555172592905662465855458936793656810422352997966047648025240162819560668696943209934966889030842329469247533077202458378240 
13462012475717519819847898602483572772785942779053266294204164012183983644350927175471346936359448170093286451958987464383447351877780220340502288456989443556198703030739598463763326272818229296891356013880372933891760495343606298734365769728 
1898143759076170131732924360796650906512836499050717893199776754665555195120223263646057395461357888931562497744031320771475064914691811293389045278494029895008687905103443356067814671225440694355427555421132397923075396335136679918598763839488 
269536413788816139754438390327986060207006761594418795608708910530958408763565379877547856620638719509551298158088996005509777856422941229887073969160234380781086282119645753382247651809497129986833925374702597071690485653167670866643577519210496 
38543707171800705947204693672221529226566388300967283997382476740262750333184049413297468095881673580587924049008224118772751693483947012773652769689219627681068289851559097527814258181392588553394063937109512548094053006650111698383170089613524992 
5550293832739301258952844259818412810486810868938634749860256268723503596381181380845791518094478094899788402923685917778417185396133629059481507541855142176336291328082138407664779316782956930820832085254567931658215839366200084338607698327436787712 
804792605747198661881041572966632512817372625583268023150070499107442733992210570019849487962650212923815940096992543600977820842230529693068745046312586436662410037223706744021688360143974812283889170034073852576540251441345380217212538939478972039168 
117499720439090992832116288798894097096208111653243305867337578809546462680228676990166097953037038867545228738836544206015747242772543752987399083313054408660345806011194916514399788794739671016954270763292243588236310551945735968925451761407986470223872 
17272458904546375894227231696563570756893750298016939422305199691910297510897851363147875478646194154767959555299954101855174918176366740705641402324211458382732114324811042992498350362873492901499478693517912739275698462574409109450082439884189157285691392 
2556323917872863685689745754130242664659089369876569411659236132929989314782944495858183473380693307077115621156827533018005172637568201191545340776938216483551201338718674731651016489817393417126549133935163283244523501548105364052138185402671685607593345024 
380892263763056705811136141833522425137514385751868304010542956307075176251718228045906283126532953271985000927766812114035827564207030130478704704445729496636065706086834330069514775449771957075699222592227134926930682005840657790068696726539328538276446339072 
57133839564458504888431685060296571931908532210186455865803960270646722738367142315408067529343188252533443527449112321315901238165762616382826568957034327205350825860530274233419660272647262828623211661421621408605336881542803886698113566366770204591606248505344 
8627209774233234615716859150561790427786140614334170094274951540226843754059425775954122173751335245626043711543725206901858679205702245898374800409085020767390642245098103515617270222380052488491066904201045183586163790136948583107296470485207866134879053228802048 
1311335885683451761825126305547756360489237141240728571855879736711764103662106676033750589145367515043653574540845545451840801505765761636941982311937741608200968766730940406168885151729010336184446584614984584762736924911924550798066001137333138306257370963437944832 
200634390509568112227684921619216654823644595589072817869184371641212860323291197641531454768897765009286224853644504344215608270318233191406526939915690030740821554669301499292543605371860283255919204507474074749968507404197672918265876450687148755325528258148585963520 
30897696138473488989801101804175762109592920239886867806863784109719298588306399485130548619596517219734367745417059104612562299226450777914781294594584887321529452753451135576999882313559351694199512576606264842745940455953370295259416104472828052098857371784585454551040 
4789142901463391195071321120698705430443839346927706590243024791904930493455109325996023636166356544245272624587373036612587182761842120703065051309330672039075223682019852076560372117214987400110541168443250609744538354280562895021882635083915363955979735593929220590403584 
747106292628289053338066409265043671365868118825898819019258250818589832432588471348651207669278062185780681147537862672781205268831748856828911352282824688248810783792517017525799340851332871591720428279844252874955471485530823760533626209240464532577214924519676447314411520 
117295687942641384449155319333017070600627486736257724979320274896395252315183980458112127652913963338426784278667178035194375485261942059339369179225802316072557680415130325303822644006892956516983079354529508587631721962401255003217486187553572103665408591362928406252528599040 
18532718694937337798302304500930615353830744697170977833911848125738743408731265124183657760557585320351800349641067169002305820196781024810967244544651842286089837708689168226745974043167695817683437504412397572585599455145478595819992066339158342725133144864204884711675726397440 
2946702272495036855030493058134150005903194371469614756281251867284626313793885816612423355490049354197511664190179773013137711205787636983674505857336271196646572958085636347157839242707589340534849518763032684903478971018909161839512485946731585720150787004335343283104414986928128 
471472363599205896804878889301464000944511099435138361005000298765540210207021730657987736878407896671601866270428763682102033792926021917387920937173803391463451673293701815545254278833214294485575923002085229584556635363025465894321997751477053715224125920693654925296706397908500480];


end
