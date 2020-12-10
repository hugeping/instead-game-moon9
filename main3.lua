--$Name: Луна-9$
--$Version: 0.1$
--$Author: Пётр Косых$

require "fmt"
fmt.dash = true
fmt.quotes = true
require 'parser/mp-ru'

mp.msg.UNKNOWN_OBJ = function(w)
	if not w then
		p "Об этом предмете ничего не сказано."
	else
		p "Об этом предмете ничего не сказано "
		p ("(",w,").")
	end
end
game.dsc = [[{$fmt b|ЛУНА-9}^^Интерактивная новелла для выполнения на средствах вычислительной техники.^Игра разработана в ОС Plan9 (9front).^^Для помощи, наберите "помощь" и нажмите "ввод".]];

VerbExtend {
	"#Talk",
	"по {noun_obj}/телефон,дт : Ring",
	":Talk"
}

Verb {
	"#Ring",
	"[по|]звон/ить",
	":Ring"
}
function mp.token.ring()
	return "{noun_obj}/телефон,вн|звонок|вызов"
end

Verb {
	"#Answer",
	"ответ/ить,отвеч/ать",
	":Answer",
	"{noun}/дт,live : Answer",
	"на {ring} : Ring"
}


global 'last_talk' (false)

function game:before_Ring(w)
	if not have 'телефон' then
		p [[У тебя нет с собой телефона.]]
		return
	end
	return false
end
function game:after_Ring(w)
	p [[Тебе некому сейчас звонить.]]
end
-- ответить
function game:before_Answer(w)
	if not w then
		if isDaemon 'телефон' then
			mp:xaction("Ring")
			return
		end
		mp:xaction("Talk")
		return
	end
	mp:xaction("Talk", w)
end
-- говорить без указания объекта
function game:before_Talk(w)
	if w then
		last_talk = w
		return false
	end
	if not last_talk or not seen(last_talk) then
		last_talk = false
		for _, v in ipairs(objs()) do
			if v:has'animate' then
				if last_talk then
					last_talk = false
					break
				end
				last_talk = v
			end
		end
		if not last_talk then
			p [[Говорить с кем? Нужно дополнить предложение.]]
			return
		end
	end
	mp:xaction("Talk", last_talk)
	return
end
-- чтобы можно было писать к чему-то -- трансляция в идти.

function mp:pre_input(str)
	local a = std.split(str)
	if #a <= 1 or #a > 3 then
		return str
	end
	if a[1] == 'в' or a[1] == 'на' or a[1] == 'во' or
		a[1] == "к" or a[1] == 'ко' then
		return "идти "..str
	end
	return str
end

function game:before_Any(ev, w)
	if ev == "Ask" or ev == "Say" or ev == "Tell" or ev == "AskFor" or ev == "AskTo" then
		if w then
			p ([[Просто попробуйте поговорить с ]], w:noun'тв', ".")
		else
			p [[Попробуйте просто поговорить.]]
		end
		return
	end
	return false
end
-- класс для переходов
Path = Class {
	['before_Walk,Enter'] = function(s)
		if mp:check_inside(std.ref(s.walk_to)) then
			return
		end
		walk(s.walk_to)
	end;
	before_Default = function(s)
		if s.desc then
			p(s.desc)
			return
		end
		p ([[Ты можешь пойти в ]], std.ref(s.walk_to):noun('вн'), '.');
	end;
	default_Event = 'Walk';
}:attr'scenery,enterable';

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" or
	ev == 'Listen' or ev == 'Smell' then
			return false
		end
		p ("Лучше оставить ", s:noun 'вн', " в покое.")
	end;
}:attr 'scenery'

Distance = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " очень далеко.");
	end;
}:attr 'scenery'

Ephe = Class {
	description = "Это не предмет.";
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " не предмет.");
	end;
}:attr 'scenery'

Furniture = Class {
	['before_Push,Pull,Transfer,Take'] = [[Пусть лучше
	{#if_hint/#first,plural,стоят,стоит} там, где
	{#if_hint/#first,plural,стоят,стоит}.]];
}:attr 'static'

Prop = Class {
	before_Default = function(s, ev)
		p ("Тебе нет дела до ", s:noun 'рд', ".")
	end;
}:attr 'scenery'

function init()
	walk 'home'
end
function start()
	local t = _'comp'.time
	if t ~= 0 then
		_'comp'.time = os.time()
	end
end
-- https://kosmolenta.com/index.php/488-2015-01-15-moon-seven
pl.description = function(s)
	p [[Тебя зовут Борис.]];
	if here() ^ 'home' then
		p [[Ты очень напряжён и эмоционально измотан.]]
	end
end
function clamp(v, l)
	if v > l then v = l end
	return v
end
function inc_clamp(v, l)
	v = v + 1
	return clamp(v, l)
end
function inc(v)
	return v + 1
end
function in_t(v, t)
	for _, vv in ipairs(t) do
		if v == vv then return true end
	end
	return false
end
obj {
	-"Лариса,жена";
	nam = 'жена';
	{
		talk = {
			[1] = [[-- Так не может продолжаться вечно. Нужно решать нашу проблему... -- начинаешь ты.^
			Лариса молча смотрит куда-то в сторону.]];
			[2] = [[-- Только нужно делать это вместе. Я и ты. Не молчи, пожалуйста...^
			Лариса пожимает плечами.]];
			[3] = [[-- Ты обещала поговорить. Так давай разговаривать! Не молчи, прошу!^
			Лариса с осторожностью бросает на тебя взгляд, затем снова отводит его в сторону.]];
			[4] = [[-- Я не могу так больше. Если это конец -- давай честно признаем это... Но нельзя оставаться в этом тупике. Я с ума схожу от безысходности!^
			-- Я, я, я... Ты думаешь только о себе! Ты никогда не думал о том, что чувствую я!? -- взрывается Лариса.]];
			[5] = [[-- Хорошо, давай поговорим об этом. Что с тобой? Почему мы становимся чужими людьми? Что я делаю не так?^
			-- Ты опять о себе... -- в голосе Ларисы чувствуется горечь.]];
			[6] = [[-- А как ты хотела? Я чувствую, что я живу в пустоте. В абсолютном вакууме! В чём смысл такой жизни? Ну, что ты молчишь?^
			-- А ты не думал, чем живу я? Ты только используешь меня. Для своего комфорта. Я -- просто твоя служанка и всегда ей была! -- Лариса вот-вот расплачется.]];
			[7] = [[-- Это какое-то дерьмо! Дело не во мне, я такой-же, каким был 17 лет назад. Это в тебе что-то изменилось! Я привык решать проблемы, решу и эту! -- ты почти теряешь контроль над собой.^
			-- Как всегда, силой? Сломать всё? Давай, ты это умеешь! -- от хлёстких слов Ларисы тебя заливает волнами обиды.]];
			[8] = [[-- Если наши отношения мертвы, то их лучше закончить, чем жить в аду! Артур уже взрослый, он поймёт... Я отдам вам квартиру и уеду, всем будет легче... -- ты почти сам веришь своим словам. Но тебе кажется, что их произносит кто-то другой.^
			-- Ты предал нашу любовь! Растоптал всё! Космонавт! -- в последних словах Ларисы слышится издёвка.]];
			[9] = [[-- Да что ты от меня хочешь, чёрт возьми?!!^
			-- Я уже больше ничего не хочу...]];
			[10] = [[-- Хорошо, выскажись ты, я выслушаю. Пойму. Главное, не молчи!^
			-- Приказываешь, как у себя, там? -- Лариса в первый раз подняла свой взгляд и тебе стало мучительно больно.]];
			[11] = [[-- Я не приказываю, я просто устал. Посмотри на меня? Мой полёт на Луну будет последним.^
			-- Я тоже устала. Давай просто пойдём спать... -- с мольбой в голосе говорит Лариса.]];
			[12] = [[-- И снова оставим проблему нерешённой? Тебя устраивает это?^
			-- Я -- мертва. Мне уже всё-равно. Просто оставь меня в покое.]];
			[13] = [[-- Я хотел бы исправить всё. Но мне нужно понимать, что происходит.^
			-- Ты должен чувствовать. В этом проблема. Ты больше не чувствуешь.]],
			[14] = [[-- Я такой же, каким был всегда! А вот ты...^
			-- Я тоже больше ничего не чувствую... -- почти шёпотом произносит Лариса.]];
			[15] = [[-- Всё это повторялось тысячу раз. Я больше не могу, извини. Когда я вернусь...^
			Звук телефонного вызова прервал тебя.^
			-- Ну, возьми трубку, ответь. Что же ты. -- с этими словами Лариса вышла из комнаты.
			]];
		};
	};
	talk_step = 0;
	description = [[Тебе кажется, что Лариса
	почти не изменилась за все эти 17 лет. Но в последние годы ваш брак трещит по швам.
	Раздражение, затаённые обиды и ссоры. Ты задыхаешься от отсутствия любви, как и она. Что стало причиной разлада? Твоя работа? Её усталость? Можно ли вырваться из этой западни?]];
	found_in = 'home';
	talk2 = false;
	before_Talk = function(s)
		if s.talk2 then
			if isDaemon'телефон' then
				p [[-- Какая-то пелена. Не понимаю, что на меня нашло...^
				-- Телефон звонит. Наверное, это по работе. -- говорит Лариса. -- Ответишь?]]
				return
			end
			p [[-- Давай попробуем ещё раз? С чистого листа. -- произносишь ты. И сразу же ощущаешь как будто вязкая тёмная пелена вдруг спала с твоего сердца.^
			Лариса ничего не ответила, но только крепче прижалась к тебе.^
			-- Прости меня...]];
			DaemonStart'телефон'
			return
		end
		s.talk_step = inc_clamp(s.talk_step, #s.talk)
		if s.talk_step == #s.talk then
			DaemonStart'телефон'
			remove(s)
		end
		p(s.talk[s.talk_step])
	end;
	['before_Touch,Kiss,Taste'] = function(s)
		if s.talk2 then
			p [[Ты поглаживаешь Ларису по волосам.]]
			return
		end
		if in_t(s.talk_step, {3, 10, 11, 13, 14}) then
			p [[Внезапно, поддавшись интуиции, ты подходишь к Ларисе и обнимаешь её. Она делает неуверенное движение, пытаясь отстраниться, но затем прижимается к тебе.]]
			s.talk2 = true
		else
			p [[Ты пытаешься обнять жену, но она отстраняется от тебя. Как всегда, ты выбрал неудачный момент.]]
		end
	end;
}:attr'scenery,animate';

room {
	nam = 'home';
	title = "гостиная";
	-"гостиная,комната";
	out_to = function()
		if isDaemon 'телефон' then
			p [[Нужно ответить на звонок. Это с работы.]]
			return
		end
		p [[Ты хочешь решить проблему, а не бежать от неё.]];
	end;
	dsc = function(s)
		p [[Ты находишься в гостиной.]]
		if _'#win':has'open' then
			p [[Сквозь окна ты видишь ночную тьму.]]
		else
			p [[Сквозь закрытые окна ты видишь ночную тьму.]];
		end
		if seen 'жена' then
			p [[В комнате только ты и твоя жена Лариса.]]
			if _'жена'.talk_step == 0 then
				p [[Ты собираешься с духом, чтобы поговорить с Ларисой о ваших отношениях.^^]]
				p [[В комнате царит напряжённая тишина.]]
			end
		end
	end;
	before_Listen = function(s)
		if isDaemon 'телефон' then
			p [[Ты слышишь мелодию вызова.]]
			return
		end
		return false
	end;
	["before_Ring,Answer"] = function(s)
		if isDaemon 'телефон' then
			DaemonStop 'телефон'
			walk 'разговор'
			return
		end
		return false
	end;
}: with {
	Ephe { -"тьма,ночь"; description = [[Уже совсем поздно.]] };
	Ephe { -"тишина"; };
	obj {
		nam = '#win';
		-"окна|окно";
		description = "За окнами -- тьма.";
		before_LetIn = "Неуместная мысль.";
	}:attr 'static,concealed,openable,enterable';
	Furniture {
		-"столик,стеклянный столик,стол";
		description = [[Стеклянный столик стоит посреди гостиной.]];
		before_Enter = [[Столик хрупкий, лучше этого не делать.]];
	}:attr 'supporter':with {
		obj {
			-"телефон,мобильный|трубка";
			nam = 'телефон';
			init_dsc = "На столике лежит телефон.";
			description = [[Твой мобильный телефон.]];
			before_Take = function(s)
				if isDaemon(s) then
					here():before_Answer()
					return
				end
				return false
			end;
			before_SwitchOff = [[Ты должен оставаться на связи.]];
			daemon = function(s)
				p [[Ты слышишь как звонит твой мобильный.]];
			end;
		}:attr 'switchable,on'
	};
}

cutscene {
	nam = "разговор";
	enter = function(s)
		remove 'телефон'
	end;
	text = {
		[[-- Да, слушаю!^
		-- Борис, извини, что так поздно. Но тут такое дело... Старт переносится. Тебе нужно завтра приехать.]];
		[[-- Завтра? Что произошло?^
		-- Я понимаю, выходные... Но у нас ситуация... Потеряна связь с лунной вахтой. Была надежда, что это временные проблемы, но они не выходят на связь уже два дня. Никаких сигналов от них.]];
		[[-- Что это может означать? Метеорит?^
		-- Неизвестно. Принято решение перенести старт Луны-9. Китайцы настаивают, да и мы хотим помочь ребятам, если... Если они ещё живы.]];
		[[-- Когда?^
		-- Приезжай, всё узнаешь. И.. Передай Ларисе мои извинения... У тебя всё в порядке? Голос какой-то...]];
		[[-- Всё в порядке, Саша, завтра буду.^
		-- Хорошо, до встречи.]],
		[[Ты смотришь в ночное окно. В затянутом дымке осеннем небе не видно звёзд.]];
	};
	next_to = 'title'
}
mp.msg.TITLE_INSIDE = "{#if_has/#where,container,в,на} {#where/пр,2}";
cutscene {
	nam = 'title';
	title = "Луна-9";
	text = [[11 ноября 2043 года пилотируемый космический корабль "Арго-3" успешно достиг орбиты Луны. На 17 дней раньше ранее запланированного срока.^^
	Командир: Борис Громов^
	Пилот командного модуля: Сергей Чернов^
	Пилот лунного модуля: Александр Катаев^^
	Миссия: cмена вахты на российско-китайской лунной базе "Луна-9". Выяснение причины пропажи связи, спасение экипажа.
	]];
	next_to = 'кресло';
	exit = function()
		p [[Ты медленно пробуждаешься. Пристёгнутый к креслу в довольно неудобной для сна позе, ты несколько секунд смотришь сквозь носовые иллюминаторы. Часть обзора загораживает посадочный модуль. А на фоне его ты видишь яркую, заполняющую всё Луну.^^
	Слева и справа от тебя, к своим креслам пристёгнуты Александр и Сергей. Они ещё спят.]];
		DaemonStart 'comp'
	end
}

Verb {
	'#ClipOff',
	'[рас|от]стегн/уть',
	'{noun}/вн : ClipOff';
	':ClipOff';
}

Verb {
	'#ClipOn',
	'[за|при]стегн/уть',
	'{noun}/вн : ClipOn';
	':ClipOn';
}

function mp:ClipOff(w)
	if not w or w == me() then
		if not seen 'belts' then
			p [[Ты не видишь здесь ремней.]]
			return
		end
		p [[Попробуй расстегнуть или застегнуть ремни.]]
		return
	end
	p (w:Noun 'вн', " нельзя расстегнуть.");
end

function mp:ClipOn(w)
	if not w or w == me() then
		mp:ClipOff()
		return
	end
	p (w:Noun 'вн', " нельзя застегнуть.");
end
obj {
	nam = 'belts';
	-"ремни";
	ClipOn = function(s)
		mp:xaction("Enter", _'кресло')
	end;
	ClipOff = function(s)
		p [[Ты расстёгиваешь ремни и выплываешь из кресла.]]
		walkout 'модуль'
	end;
	description = function(s)
		if where(me()) ^ 'кресло' then
			p [[Ремни застёгнуты.]]
		else
			p [[Ремни расстёгнуты.]]
		end
	end;
}:attr 'concealed,static';
VerbExtend {
	'#GetOff',
	'из {noun}/рд,scene: GetOff'
}
local start_time = 11 + 32*60 + 67*60*60;
function dark_side()
	return _'comp'.dist < 532 and (math.floor(_'comp'.otime / (33 * 60)) % 2 == 0)
end
room {
	nam = 'модуль';
	-"модуль,корабль";
	title = "Командный модуль";
	dsc = function(s)
		if not dark_side() then
			p [[В командном модуле светло.]];
		else
			p [[Неяркий свет звёзд и тёмной стороны Луны освещают командный модуль.]]
		end
		p [[Корабль медленно вращается вокруг своей оси.]]
		if dark_side() then
			p [[Ты видишь, как яркие солнечные лучи проникают сквозь иллюминаторы и скользят по стенам.]]
		end
	end;
	before_Wait = function(s)
		update_comp(5 * 60) -- 5 min
		return false
	end;
}:with {
	Ephe { nam = '#лучи', -"лучи,Солнц*",
		description = function(s)
			if dark_side() then
				p "Сейчас корабль находится за Луной, поэтому Солнца не видно."
			else
				p "Солнечные лучи очень яркие. Корабль вращается, чтобы не допустить перегрева."			end
		end
	};
	Careful { nam = '#win', -"иллюминаторы/но|иллюминатор/но",
		description = function(s)
			p [[Иллюминаторы как всегда сильно запотевают.]]
			if not dark_side() then
				p [[При ярком освещении звёзды едва различимы. А вот вид необычно громадной Луны поражает своей грандиозностью.]];
			else
				p [[Сейчас, когда корабль плывёт над тёмной стороной Луны, звёзды выглядят необычно ярко.]]
			end
		end
	};
	Careful {
		nam = '#radio';
		-"радио";
		daemon = function(s)
			p [["Перемен, требуют наши сердца!..."^^]]
			p [[-- "Арго", "Заря". Как слышно? Приём? Доложите обстановку.]]
			_'Александр'.sleep = false
			_'Сергей'.sleep = false
			s:daemonStop()
		end;
	};
	Distance { -"Луна,кратер*,морщи*,рисун*",
		description = function(s)
			if not dark_side() then
				p [[Изрытая кратерами поверхность завораживает. Луна -- всегда такая привычная, сейчас выглядит угрожающе чужой. Некоторое время ты отрешённо следишь за причудливым рисунком её морщин.]]
			else
				p [[Даже находясь в тени, лунная поверхность отражает достаточно звёздного света, чтобы ты мог различить грубый рисунок её поверхности.]]
			end
		end
	};
	Distance { -"звёзды/но,мн",
		description = function(s)
			if not dark_side() then
				p [[Звёзды там, только их не видно. Мешает яркий свет.]]
			else
				p [[Яркие россыпи звёзд. И каждая звезда -- свой мир. Такой близкий и такой бесконечно далёкий.]]
			end
		end
	};
	Distance { -"посадочный модуль", desciption = [[Это лунный модуль. Он должен доставить вас на базу "Луна-9", а затем вернуть обратно. ]] };
	Prop { -"стены/но,жр" };
	Ephe { -"свет",
		description = function()
			if not dark_side() then
				p [[Солнце светит в боковые иллюминаторы. А сквозь носовые в корабль проникает серебряный свет Луны.]]
			else
				p [[Сейчас корабль освещает только свет звёзд.]]
			end
		end
	};
	Prop {
		-"кресла/мн,ср|левое кресло|правое кресло";
		description = [[В командном модуле установлены три кресла. Твоё кресло командира -- среднее.]];
	};
	obj {
		title = 'в кресле';
		nam = 'кресло';
		-"кресло";
		inside_dsc = 'Ты пристёгнут ремнями к креслу командира экипажа.';
		description = [[Кресло командира экипажа.]];
		before_LetIn = function(s)
			p [[Ты подлетаешь к креслу командира и пристёгиваешься.]]
			place(me(), s)
		end;
		before_LetGo = function(s)
			mp:xaction("ClipOff", _'belts')
		end;
		obj = { 'belts' };
	}:attr 'supporter,open,concealed,enterable,static';
	obj {
		nam = 'Сергей';
		-"Сергей,Серёжа";
		sleep = true;
		description = function(s)
			p [[Сергей Чернов -- пилот командного модуля. Занимает кресло слева от командирского.]]
			if s.sleep then
				 p [[Сергей спит.]];
			end
		end;
		['before_WakeOther,Attack,Touch,Talk'] = function(s)
			if s.sleep then
				p [[Пусть поспит ещё немного. ЦУП скоро разбудит его и Сашу по радио. Пока ты можешь просто {$fmt em|подождать}.]];
			else
				return false
			end
		end;
	}:attr 'animate';
	obj {
		nam = 'Александр';
		-"Александр,Саша";
		sleep = true;
		['before_WakeOther,Attack,Touch,Talk'] = function(s)
			if s.sleep then
				p [[Пусть поспит ещё немного. ЦУП всё-равно скоро его разбудит. Пока ты можешь просто {$fmt em|подождать}.]];
			else
				return false
			end
		end;
		description = function(s)
			p [[Александр Катаев -- пилот лунного модуля. Занимает правое кресло от командира.]]
			if s.sleep then
				p [[Пока он спит.]];
			end
		end;
	}:attr 'animate';
	obj {
		nam = 'comp';
		time = 0;
		dist = 3112;
		speed = 2.336;
		otime = 0;
		start = start_time;
		fltime = start_time;
		-"компьютер,бортовой компьютер";
		dsc = [[Бортовой компьютер помигивает неяркими огоньками.]];
		description = function(s)
			if s.time == 0 then
				s.time = os.time()
			end
			show_stats()
		end;
		daemon = function(s)
			update_comp()
			if s.dist < 2200 and s:once'wake' then
				DaemonStart '#radio'
				p [[Внезапно, тишину командного модуля нарушает звук радио.^^
				"Вместо тепла зелень стекла^
				Вместо огня дым!"...^^
				Кто-то там в ЦУП решил быть оригинальным.]]
			end
		end;
	}:attr'static';
	Ephe { -"огоньки,огни", description = [[Похоже, всё в порядке.]] };
}

function update_comp(delta)
	local side = dark_side()
	if _'comp'.time == 0 then
		_'comp'.time = os.time()
	end
	local flt = _'comp'.fltime
	if delta then
		flt = flt + delta
	else
		local cur = os.time()
		delta = cur - _'comp'.time
		if delta < 0 then
			delta = 0
		end
		if delta > 3*60 then
			delta = 3*60
		end
		flt = flt + delta
		_'comp'.time = cur
	end
	if _'comp'.otime > 0 then
		_'comp'.otime = _'comp'.otime + delta
	end
	-- print(_'comp'.dist, delta)
	_'comp'.fltime = flt
	local dist = _'comp'.dist - (delta*_'comp'.speed)
	if dist < 532 and _'comp'.otime == 0 then
		_'comp'.otime = 1
	end
	if dist < 110 then
		dist = 110
	end
	_'comp'.dist = dist
	_'comp'.speed = _'comp'.speed + 0.00001 * delta
	if dark_side() ~= side then
		if dark_side() then
			p [[Корабль вошёл в тень Луны. Яркий солнечный свет перестал проникать сквозь иллюминаторы.]]
		else
			p [[Корабль вышел из тени Луны. Яркий солнечный свет залил всё вокруг.]];
		end
	end
end

function show_stats(flt)
	flt = flt or _'comp'.fltime
	local sec = flt % 60
	local min = math.floor(flt / 60 % 60)
	local hh = math.floor(flt / 60 / 60)
	pn ([[Время полёта: ]], hh, " час. ", min, " мин. ", sec, " сек.")
	pn ([[Расстояние: ]], string.format("%.2f", _'comp'.dist), ' км');
	p ([[Скорость: ]], string.format("%.3f", _'comp'.speed), ' км/с');
end

-- эпизод 1
-- вход в тень Луны, видны звёзды
-- просыпается. Остальные спят.
-- 562км от Луны, 2,336 км/с скорость
-- 75 часов, 41 минута, 23 секунды
-- через 8 минут.
-- развернуть корабль вперёд двигателями.
-- вкл двигатель на 5.57
-- эллиптическая орбита 114, 313
-- 17 секунд работы двигателя
-- круговая 99 (периселение), 120км(апоселение)
-- проверка лунного модуля
-- стёкла? течь?

-- эпизод 2 -- посадка,
-- гора Малаперт, "Пик вечного света" у Южного полюса.
-- 89% светло, затенённые кратеры (лёд)
-- Кратер Малаперт имеет полигональную форму и практически полностью разрушен. Вал представляет собой нерегулярное кольцо пиков окружающих чашу кратера, западная часть вала перекрыта безымянным кратером. Юго-западная часть вала формирует возвышение в виде хребта вытянутого с востока на запад высотой около 5000 м неофициально именуемое пиком Малаперта (иногда Малаперт Альфа). Дно чаши пересеченное, со множеством холмов. Вследствие близости к южному полюсу часть кратера практически постоянно находится в тени, что затрудняет наблюдения.
-- На пике -- передатчик для связи с Землёй.
-- Там же -- солнечная батарея.
-- Собираемая конструкция - в тени кратера.

-- Эпизод 3
-- По радиомаякам идут пешком или едут к Луне-9
