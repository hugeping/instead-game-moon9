--$Name: Луна-9$
--$Version: 0.1$
--$Author: Пётр Косых$

require "fmt"
fmt.dash = true
fmt.quotes = true
require 'parser/mp-ru'
require 'snapshots'
mp.cursor = fmt.img 'gfx/cursor.png'
mp.msg.Enter.EXITBEFORE = function()
	if me():where() ^'place' then
		p [[Но ты пристёгнут ремнями!]]
		return
	end
	p "Сначала нужно {#if_has/#where,supporter,слезть с {#where/рд}.,покинуть {#where/вн}.}"
end

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
	"по {noun}/дт : Ring",
	"по {noun}/дт с {noun}/тв,scene : Ring",
	"~ с {noun}/тв,scene по {noun}/дт : Ring reverse",
	":Talk"
}
VerbExtendWord {
	"#Exit",
	"вернуться"
}
Verb {
	"сверл/ить,просверл/ить",
	"{noun}/вн : Screw",
}
function game:before_Screw(w)
	if not have'screw' then
		p [[Но у тебя нет дрели!]]
		return
	end
	mp:xaction("Attack", w, _'screw')
end

Verb {
	"#Ring",
	"[по|]звон/ить",
	":Ring"
}
VerbExtend {
	"#Push",
	"{noun}/вн вперёд : Push",
	"{noun}/вн от себя : Push",
	"{noun}/вн назад : Pull",
	"{noun}/вн на себя : Pull",
	"{noun}/вн направо|вправо : PushRight",
	"{noun}/вн налево|влево : PushLeft",
}
VerbExtend {
	"#Pull",
	"{noun}/вн вперёд: Push",
	"{noun}/вн от себя : Push",
	"{noun}/вн назад : Pull",
	"{noun}/вн на себя : Pull",
	"{noun}/вн направо|вправо : PushRight",
	"{noun}/вн налево|влево : PushLeft",
}
function mp:PushRight(w)
	mp:xaction("Push", w)
end

function mp:PushLeft(w)
	mp:xaction("Push", w)
end

function mp.token.ring()
	return "{noun_obj}/телефон,вн|звонок|вызов"
end

Verb {
	"#Answer",
	"ответ/ить,отвеч/ать",
	":Answer",
	"{noun}/дт : Answer",
	"на {ring} : Answer"
}

VerbExtend {
	"#Attack",
	"{noun}/вн {noun}/тв,held : Attack",
	"~ {noun}/тв,held {noun}/вн : Attack reverse",
}

Verb {
	"разобрать,разбер/и",
	"{noun}/вн : Attack",
	"{noun}/вн {noun}/тв,held : Attack",
	"~ {noun}/тв,held {noun}/вн : Attack reverse",
}
game:dict {
	["шуруповёрт/мр,С,но"] = {
		"шуруповёрт/им",
		"шуруповёрт/вн",
		"шуруповёрта/рд",
		"шуруповёрту/дт",
		"шуруповёртом/тв",
		"шуруповёрте/пр",
	}
}
global 'last_talk' (false)
function game:before_Ring(w)
	if (not w or w^'телефон') and not have 'телефон' then
		p [[У тебя нет с собой телефона.]]
		return
	end
	return false
end
function game:after_Ring(w)
	if not w or w^'телефон' then
		p [[Тебе некому сейчас звонить.]]
		return
	end
	p (w:Noun(), " не телефон и не радио, чтобы говорить c ", w:it 'вн', " помощью.");
end

-- ответить
function game:before_Answer(w)
	if not w then
		return false
	end
	mp:xaction("Talk", w)
end

function game:after_Answer(w)
	mp:xaction("Talk", w)
end
global 'gravity' ('earh')
function game:before_Any(ev, w)
	if ev == 'Jump' or ev == 'JumpOver' then
		if gravity then
			return
		end
		p [[В невесомости?]]
		return
	end
	if _'скафандр':has'worn' and (ev == 'Taste' or
		ev == 'Eat' or
		ev == 'Kiss' or
		ev == 'Talk' or ev == 'Smell') then
		if ev == 'Talk' and _'скафандр'.radio then
			if not w then
				return false
			end
			if w ^ 'Беркут' or w ^ 'Арго' or w ^ 'Заря' then
				return false
			end
		end
		p [[В скафандре неудобно это делать.]];
		return
	end
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

-- класс для переходов
Path = Class {
	['before_Walk,Enter'] = function(s)
		if mp:check_inside(std.ref(s.walk_to)) then
			return
		end
		if _(s.walk_to):has 'door' then
			mp:xaction("Enter", _(s.walk_to))
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
		p ("Лучше быть с ", s:noun 'тв', " поосторожнее.")
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
		p ("Лучше оставить ", s:noun 'вн', " в покое.")
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
	p [[Тебя зовут Борис Громов.]]
	if not here() ^ 'home' then
		p [[Тебе 43 года и ты -- космонавт.]];
	end
	if _'скафандр':has'worn' then
		p [[На тебе надет скафандр.]]
	end
	if here() ^ 'home' then
		p [[Ты очень напряжён и эмоционально измотан.]]
	end
end
pl.scope = std.list {}

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
	before_Attack = [[Тебя захлёстывает волна болезненной агрессии, но ты не поддаёшься ей.]];
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
		-- Неизвестно. Принято решение перенести старт. Китайцы настаивают, да и мы хотим помочь ребятам, если... Если они ещё живы.]];
		[[-- Когда?^
		-- Приезжай, всё узнаешь. И.. Передай Ларисе мои извинения... У тебя всё в порядке? Голос какой-то...]];
		[[-- Всё в порядке, Саша, завтра буду.^
		-- Хорошо, до встречи.]],
		[[Ты смотришь в ночное окно. В затянутом дымке осеннем небе не видно звёзд.]];
	};
	next_to = 'title'
}
cutscene {
	nam = 'badend1';
	title = 'Луна-9';
	text = [[Экипаж "Арго-3" не сумел выйти на лунную орбиту за время облёта обратной
	стороны Луны. Корабль продолжил своё движение и направился обратно к Земле...^^
	Но всё могло быть по-другому.]];
	onexit = function(s)
		snapshots:restore()
		mp:clear()
	end;
}
-- mp.msg.TITLE_INSIDE = "{#if_has/#where,container,в,на} {#where/пр,2}";
cutscene {
	nam = 'title';
	title = "Луна-9";
	text = [[15 ноября 2043 года пилотируемый космический корабль "Арго-3" успешно достиг орбиты Луны. На 17 дней раньше ранее запланированного срока.^^
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
		snapshots:make()
		gravity = false
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
		if not _'belts':visible() then
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
	-"ремни|ремень";
	["Worn,ClipOn"] = function(s)
		if me():inside('кресло') or me():inside('place') then
			p [[Ты уже пристёгнут.]]
			return
		end
		if here()^'moonmod' then
			mp:xaction("Enter", _'place')
		else
			mp:xaction("Enter", _'кресло')
		end
	end;
	["Disrobe,ClipOff"] = function(s)
		if here()^'moonmod' then
			p [[Ты расстёгиваешь ремни и покидаешь стойку.]]
			walkout 'moonmod'
		else
			p [[Ты расстёгиваешь ремни и выплываешь из кресла.]]
			walkout 'модуль'
		end
	end;
	description = function(s)
		p [[Крепкие надёжные ремни, с помощью которых космонавты фиксируют своё положение во время полёта.]]
		if where(me()) ^ 'кресло' or where(me()) ^ 'place' then
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

door {
	-"люк";
	nam = 'люк';
	found_in = { 'модуль', 'sect2' };
	door_to = function(s)
		if here() ^ 'модуль' then
			return 'sect2';
		end
		return 'модуль'
	end;
	description = [[Этот люк связывает командный и служебный отсеки.]];
	before_Open = function(s)
		if not _'модуль'.engine then
			p [[Что ты забыл в служебном отсеке?]]
			return
		end
		if here()^'sect2' and _'#дверь':has'open' and s:hasnt'open' then
			p [[Нужно закрыть дверь в агрегатный отсек!]]
			return
		end
		return false
	end;
	dsc = function(s)
		if here() ^'модуль' then
			return
		else
			p 'Люк в командный отсек '
		end
		if s:has'open' then
			p 'открыт.'
		else
			p 'закрыт.'
		end
	end;
}:attr 'static,openable';

room {
	nam = 'модуль';
	-"командный отсек,корабль";
	title = "Командный отсек";
	rot = true;
	reverse = false;
	marsh = false;
	engine = false;
	A = false;
	B = false;
	dsc = function(s)
		if not dark_side() then
			p [[В командном отсеке светло.]];
		else
			p [[Неяркий свет звёзд и пепельный свет Луны освещают командный отсек.]]
		end
		if s.rot then
			p [[Корабль медленно вращается вокруг своей оси.]]
		end
		if not dark_side() then
			pr [[Ты видишь, как яркие солнечные лучи проникают сквозь иллюминаторы]];
			if s.rot then
				p " и скользят по стенам."
			else
				p "."
			end
		end
		p [[Позади кресел расположен люк, ведущий в служебный отсек.]]
	end;
	['before_Open,Close'] = function(s, w)
		if w^'люк' and me():where() ^ 'кресло' then
			p [[Из кресла ты не можешь сделать это.]]
			return
		end
		return false
	end;
	before_Answer = function(s)
		if _'#radio'.ack then
			mp:xaction("Ring", _'#radio')
			return
		end
		return false
	end;
	before_Listen = function(s)
		if s.engine and not _'модуль'.B then
			p [[Ты слышишь звуковой сигнал о неполадках, который издаёт бортовой компьютер.]]
			return
		end
		return false
	end;
	before_Wait = function(s)
		if dark_side() and _'comp'.speed > 2.0 then
			p(string.format("Скорость Арго-3 составляет %.02f км/с. Если не снизить скорость, то после того как корабль обогнёт обратную сторону Луны, он направится обратно к Земле. Не время ждать -- время действовать!", _'comp'.speed))
			return
		end
		update_comp(5 * 60) -- 5 min
		return false
	end;
}:with {
	Ephe { nam = '#лучи', -"лучи,Солнц*",
		description = function(s)
			if dark_side() then
				p "Сейчас корабль находится в тени Луны, поэтому Солнца не видно."
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
				p [[Сейчас, когда корабль находится в тени Луны, звёзды выглядят необычно ярко.]]
			end
		end
	};
	Careful {
		nam = '#radio';
		ack = false;
		-"радио,ЦУП|Заря";
		description = [[Радио невозможно увидеть. Оно встроено в корабль.]];
		before_SwitchOff = [[Не стоит этого делать.]];
		["before_SwitchOn,Talk"] = function(s)
			mp:xaction("Ring", s)
		end;
		before_Ring = function(s)
			if not s.ack then
				if dark_side() then
					p [[Пока корабль плывёт над обратной стороной Луны связь с ЦУП невозможна.]]
				else
					if _'comp'.speed < 2 then
						s:daemonStop()
						walk 'stage2'
						return
					end
					p [[Сейчас нет необходимости связываться с ЦУП.]]
				end
				return
			end
			if me():where() ~= _'кресло' then
				p [[Сначала нужно вернуться в кресло.]]
				return
			end
			pn [[-- Заря, Арго-3. Обстановка нормальная. Всё штатно. Готовимся к манёвру.]]
			p [[-- Вас понял, Арго-3. Приступайте.]]
			s.ack = false
			-- s:daemonStop()
			return
		end;
		daemon = function(s)
			if not here() ^ 'модуль' then
				return
			end
			if s:once 'ack' then
				p [["Перемен, требуют наши сердца!..."^^]]
				pn [[-- Арго-3, Заря. Как слышно? Приём? Доложите обстановку.]]
				p [[Ты видишь, что Александр и Сергей проснулись и потягиваются на своих креслах, разминая мышцы.]]
				_'Александр'.sleep = false
				_'Сергей'.sleep = false
				s.ack = true
				return
			end
			if dark_side() then
				return
			end
			if time() % 3 ~= 1 or not me():inroom()^'модуль' then
				return
			end
			if s.ack then
				pn [[-- Арго-3, Заря. Как слышно? Почему не выходите на связь?]]
				p [[-- Командир, надо {$fmt em|ответить}! -- беспокоится Александр.]]
				return
			end
			if _'comp'.speed < 2 then
				if s:once 'stage2' then
					pn [[Вдруг, радио оживает и пространство отсека наполняется звуком позывных с ЦУП.]]
				end
				pn [[-- Арго-3, Заря! Ответьте!]]
			end
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
				p [[Сейчас корабль освещается только светом звёзд и пепельным светом Луны.]]
			end
		end
	};
	Prop {
		-"кресла/мн,ср|левое кресло|правое кресло";
		description = [[В командном отсеке установлены три кресла. Твоё кресло командира -- среднее.]];
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
			p [[Тебе мешают ремни.]]
		--	mp:xaction("ClipOff", _'belts')
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
				return
			elseif mp.event == 'Talk' then
				if _'comp'.prog then
					pn [[-- Программа активирована?]]
					p [[-- Да, всё готово.]]
					return
				end
				if s:where().rot and _'comp'.speed > 2 then
					pn [[-- Сережа, активируй программу стабилизации корабля.]]
					p [[-- Понял. Активирую. -- Сергей быстро вбил код программы в компьютер.]];
					_'comp'.prog = 1;
					return
				end
				if not s:where().reverse then
					pn [[-- Сергей, теперь программу разворота на 180 градусов.]]
					p [[-- Сделано, командир.]]
					_'comp'.prog = 2
					return
				end
				if not s:where().marsh then
					pn [[-- Программу включения маршевого двигателя на торможение.]]
					pn [[-- Программу включения маршевого двигателя на 17 секунд ввёл.]];
					_'comp'.prog = 3
					return
				end
				if s:where().engine then
					if _'comp'.speed < 2 then
						p [[-- Успели!^
						-- Я тоже рад, командир! Надеюсь, ЦУП даст добро на продолжение миссии, хотя мне и придётся торчать здесь одному на орбите.]];
						if not s:where().rot then
							p [[^-- Активируй программу пассивного термального контроля.^
							-- Сделано!]];
							_'comp'.prog = 4
						end
						return
					end
					if not s:where().A then
						p [[-- Сергей, что происходит?^-- Какая-то проблема. Что на компьютере?^-- Сейчас посмотрю!]];
					elseif _'клапан'.on then
						p [[-- Предохранительный клапан закрыт.^
						-- Хорошо, я переключился на топливный контур B и скорректировал программу.^
						-- Активировал?^
						-- Нет ещё. Выполнять?^
						-- Да.^
						-- Программа включения маршевого двигателя активирована!]];
						_'comp'.prog = 3
					else
						p [[-- Проблема с клапаном подачи топлива!^
						-- Возможно, короткое замыкание в контуре! Я могу переключиться на контур B, только...^
						-- Что?^
						-- Нет гарантий, что при включении двигателя не откроется и клапан контура A, а тогда...^
						-- Что делать?^
						-- Можно перекрыть предохранительный клапан контура A. В агрегатном отсеке к ним предусмотрен доступ.]]
					end
					return
				end
			end
			return false
		end;
	}:attr 'animate';
	obj {
		nam = 'Александр';
		-"Александр,Саша";
		sleep = true;
		['before_WakeOther,Attack,Touch,Talk'] = function(s)
			if s.sleep then
				p [[Пусть поспит ещё немного. ЦУП всё-равно скоро его разбудит. Пока ты можешь просто {$fmt em|подождать}.]];
				return
			elseif mp.event == 'Talk' then
				if _'модуль'.engine then
					p [[-- Саша, что с орбитой?^]]
					if _'comp'.speed < 2 then
						p [[-- Выходим! Уверен, "Заря" одобрит высадку, даже не смотря на неполадки с топливной системой и мы оставим свои следы на Луне! Ты уже {$fmt em|разговаривал с ЦУП}, командир?]]
					else
						p [[-- Почти 2-я космическая... Будем болтаться как в цирке на батуте.]]
					end
					return
				end
				p [[-- Как настрой, Саша?^
				-- Всё в порядке, командир.]]
				return
			end;
			return false
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
		badend = false;
		dist = 2570;
		speed = 2.536;
		otime = 0;
		prog = false;
		start = start_time;
		fltime = start_time;
		-"компьютер,бортовой компьютер";
		dsc = function(s)
			if _'модуль'.engine == 1 and not _'модуль'.B then
				p [[Бортовой компьютер издаёт звуковой сигнал.]]
			else
				p [[Бортовой компьютер помигивает неяркими огоньками.]];
			end
		end;
		description = function(s)
			if s.time == 0 then
				s.time = os.time()
			end
			show_stats()
		end;
		daemon = function(s)
			if not here() ^ 'модуль' then
				return
			end
			update_comp()
			if s.dist < 2200 and s:once'wake' then
				DaemonStart '#radio'
				p [[Внезапно, тишину командного отсека нарушает звук радио.^^
				"Вместо тепла зелень стекла^
				Вместо огня дым!"...^^
				Интересно, кто в ЦУП поставил эту песню?]]
			end
			if s.badend then
				walk 'badend1'
			end
		end;
	}:attr'static':with {
		Careful {
			-"кнопка";
			description = [[Заметная красная кнопка прямоугольной формы.]];
			before_Push = function(s)
				local prog = _'comp'.prog
				if prog == 1 then
					if not dark_side() then
						p [[Для начала манёвра выхода на лунную орбиту, нужно подождать, пока корабль не начнёт огибать обратную сторону Луны.]]
					else
						_'comp'.prog = false
						p [[Ты нажал на кнопку. Послышался гул -- это ненадолго включились маневровые двигатели. Корабль замедлил, а затем совсем прекратил продольное вращение.]]
						_'модуль'.rot = false
					end
				elseif prog == 2 then
					_'comp'.prog = false
					_'модуль'.reverse = true
					p [[Ты нажал на кнопку выполнения программы и снова услышал работу маневровых двигателей. Корабль развернулся так, чтобы сопло маршевого двигателя было направлено по ходу движения. Всё готово для того, чтобы начать торможение и переход на лунную орбиту.]]
				elseif prog == 3 then
					if not me():where() ^ 'кресло' then
						p [[Перед торможением надо сесть в кресло.]]
						return
					end
					if _'модуль'.B then
						_'comp'.speed = 1.6
						p [[Не без опаски ты нажал на кнопку активации. Послышался низкий гул маршевого двигателя. Все, затаив дыхание, ждали. Наконец, отработав положенное время, двигатель отключился и вновь наступила тишина.]]
						_'comp'.prog = false
						return
					end
					if _'модуль'.marsh then
						p [[Не стоит включать маршевый двигатель, пока не перекрыт предохранительный клапан.]]
						return
					end
					_'comp'.prog = false
					_'модуль'.marsh = true
					p [[Корабль вздрогнул. Со стороны служебного отсека послышался сильный и низкий гул. Это запустился маршевый двигатель. 1, 2, 3, 4, 5... секунд. Вдруг, гул прекратился так же внезапно, как и начался. Что-то пошло не так! Двигатель должен был проработать 17 секунд!]]
					_'comp'.speed = 2.398
					_'модуль'.engine = 1
				elseif _'comp'.prog == 4 then
					_'модуль'.rot = true
						p [[Ты нажал на кнопку выполнения программы и услышал, как на короткое время включились маневровые двигатели. Корабль снова начал медленно вращаться вокруг своей оси.]]
					_'comp'.prog = false
				else
					p [[На космическом корабле стоит быть более осторожным.]]
				end
			end;
		}
	};
	Ephe { -"огоньки,огни", description = function(s)
			if _'модуль'.engine then
				p [[Похоже, у нас проблемы!]]
				return
			end
			p [[Похоже, всё в порядке.]]
		end
	};
	Path {
		-"служебный отсек";
		desc = [[Ты можешь пойти в служебный отсек.]];
		walk_to = 'люк';
	};
}
room {
	nam = 'sect2';
	title = "служебный отсек";
	-"служебный отсек";
	dsc = function(s)
		p [[В служебном отсеке почти всё пространство занято различным оборудованием.]];
	end;
	out_to = '#дверь';
	in_to = 'люк';
	onexit = function(s, w)
		if w ^ 'агрегатный отсек' and _'люк':has'open' then
			p [[Агрегатный отсек не герметичен. Сначала следует закрыть люк командного отсека.]]
			return false
		end;
		if w ^ 'модуль' and _'#дверь':has'open' then
			p [[Следует сначала закрыть дверь в агрегатный отсек.]];
			return false
		end
	end
}: with {
	Prop { -"оборудование" };
	door {
		-"дверь";
		nam = '#дверь';
		["before_Open,Close"] = function(s)
			if _'#lever'.on then
				p [[Дверь заблокирована рычагом.]]
				return
			end
			if mp.event == "Open" and _'люк':has'open' and s:hasnt 'open' then
				p [[Агрегатный отсек не герметичен. Сначала нужно закрыть люк в командный отсек.]]
				return
			end
			if _'скафандр':hasnt'worn' then
				p [[Агрегатный отсек не герметичен!]]
				return
			end
			return false
		end;
		description = function()
			p [[Тяжёлая межотсечная дверь покрашена в желто-чёрные цвета. Это напоминает тебе об опасности. Агрегатный отсек не герметичен!]]
			return false
		end;
		door_to = 'агрегатный отсек';
	}:attr'static,scenery,openable';
	Careful {
		-"рычаг";
		nam = '#lever';
		on = true;
		dsc = [[В стену встроен рычаг, блокирующий дверь в агрегатный отсек.]];
		description = [[Рычаг покрашен в красный цвет, чтобы напоминать экипаж об опасности выхода в негерметичный агрегатный отсек.]];
		before_Transfer = function(s, w) if w == me() or w ^ '@out_to' then mp:xaction("Pull", s) else return false end end;

		['before_Push,Pull'] = function(s)
			if _'#дверь':has 'open' then
				p [[Сначала нужно закрыть дверь.]]
				return
			end
			s.on = not s.on
			if s.on then
				p [[Ты заблокировал межотсечную дверь рычагом.]]
			else
				p [[Ты разблокировал межотсечную дверь рычагом.]]
			end
		end;
	}:attr 'static,~scenery';
	Path { -"агрегатный отсек",
		desc = function(s)
			p "Ты можешь выйти в агрегатный отсек.";
		end;
		walk_to = '#дверь';
	};
	Path { -"командный отсек",
		desc = function(s)
			p "Ты можешь вернуться в командный отсек.";
		end;
		walk_to = 'люк';
	};
	obj {
		-"скафандр";
		nam = 'скафандр';
		radio = false;
		scope = { };
		dsc = function(s)
			if s:inroom() ^ 'sect2' then
				return
			end
			return false
		end;
		description = function(s)
			if s:has'worn' then
				p [[Скафандр в полном порядке.]]
				return
			end
			p [[Ослепительно белый скафандр для выхода в открытый космос.]]
		end;
		after_Wear = function(s)
			enable 'радио'
			return false
		end;
		before_Disrobe = function(s)
			if here() ^ 'sect2' and _'#дверь':has'open'
				or here() ^ 'агрегатный отсек' then
				p [[Без скафандра ты умрёшь!]]
				return
			end
			if (here() ^ 'moonmod' or here() ^'moontech') and _'alex'.state >= 3 then
				p [[Не стоит сейчас снимать скафандр. Это опасно для жизни.]]
				return
			end
			return false
		end;
		after_Disrobe = function()
			disable 'радио'
			return false
		end;
	}:attr'clothing':with {
		Careful { -"радио"; nam = 'радио';
			description = "Радио встроено в скафандр.";
				before_Ring = function(s, w)
				mp:xaction("Talk", w)
			end }:disable();
	};

	Careful {
		-"скафандры";
		description = [[Скафандры для выхода в открытый космос.]];
		before_Take = "Зачем тебе все скафандры?";
	}:attr'clothing,~scenery';
}
room {
	-"отсек";
	title = 'агрегатный отсек';
	nam = 'агрегатный отсек';
	dsc = [[В агрегатном отсеке работает дежурное тусклое освещение. Ты видишь здесь: топливные баки, батареи, бачки с водородом, топливные элементы и клапаны.]];
	out_to = 'sect2';
}:with {
	Ephe { -"освещение|свет"; };
	Path {
		-"служебный отсек";
		desc = [[Ты можешь вернуться в служебный отсек.]];
		walk_to = 'sect2';
	};
	Careful {
		-"топливные баки,баки";
		description = [[С ними всё в порядке.]];
	};
	Careful {
		-"бачки";
		description = [[Не похоже, что проблема связана с утечкой водорода.]];
	};
	Careful {
		-"батареи";
		description = [[С электричеством порядок.]];
	};
	Careful {
		-"топливные элементы,элементы";
		description = [[Проблема с маршевым двигателем не связана с топливными элементами.]];
	};
	Careful {
		nam = 'клапан';
		-"предохранительный клапан,клапан";
		on = false;
		before_Turn = function(s)
			s.on = not s.on
			p [[Ты с трудом поворачиваешь ручку клапана.]]
			if s.on then
				p [[Теперь он перекрыт.]]
				_'модуль'.B = true
			else
				p [[Теперь он открыт.]]
				_'модуль'.B = false
			end
		end;
		description = function(s)
			if not s.on then
				p [[Чтобы перекрыть клапан, достаточно его повернуть.]];
			else
			 	p [[Клапан перекрыт.]]
			end
		end;
	}:disable();
	Careful {
		-"клапаны";
		description = function()
			p [[Предохранительные клапаны подачи топлива.]];
			if _'модуль'.A then
				p [[Ты видишь предохранительный клапан контура A.]]
				_"клапан":enable()
			end
		end;
	};
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
		if delta > 2*60 then
			delta = 2*60
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
	if dist > 110 then
		_'comp'.speed = _'comp'.speed + 0.00001 * delta
	end
	if dark_side() ~= side then
		if dark_side() then
			p [[Корабль вошёл в тень Луны. Яркий солнечный свет перестал проникать сквозь иллюминаторы.]]
		else
			p [[Корабль вышел из тени Луны. Яркий солнечный свет залил всё вокруг.]];
			if _'comp'.speed > 2.0 then
				_'comp'.badend = true
			end
		end
	end
end
function get_time(flt)
	local flt = _'comp'.fltime
	local sec = flt % 60
	local min = math.floor(flt / 60 % 60)
	local hh = math.floor(flt / 60 / 60)
	return  string.format("%d  час. %d мин. %d сек.", hh, min, sec)
end
function show_stats()
	pn ([[Время полёта: ]], get_time())
	pn ([[Расстояние: ]], string.format("%.2f", _'comp'.dist), ' км');
	pn ([[Скорость: ]], string.format("%.3f", _'comp'.speed), ' км/с');
	if _'модуль'.engine then
		_'модуль'.A = true
		if _'модуль'.B then
			pn [[Подача топлива: через контур B]];
		else
			pn [[Клапан подачи топлива, контур A: ошибка]]
		end
	end
	if _'comp'.prog then
		local progs = {
			"стабилизация";
			"разворот на 180";
			"вкл. маршевый двигатель";
			"термальный контроль";
		}
		pn ("Программа: ", progs[_'comp'.prog])
		pn [[Ты видишь, что кнопка "выполнить" подсвечена красным.]]
	end
end
global 'stage' (false)
cutscene {
	nam = 'stage2';
	title = 'Командный отсек';
	text = {
	[[-- Заря, Арго на связи!]],
	[[-- Ох, ребята! До чего же мы рады вас слышать!]],
	[[...]],
	};
	next_to = 'moonmod';
	exit = function()
		_'comp'.time = _'comp'.time + 167*60
		pn [[Прошло 2 часа 47 минут...]]
		p ([[Полётное время: ]], get_time())
		take 'скафандр'
		_'скафандр':attr'worn'
	end;
}

room {
	-"отсек,модуль,корабль";
	nam = 'moontech';
	title = "лунный модуль (технический отсек)";
	u_to = 'moonmod';
	dsc = [[В техническом отсеке работает только дежурное освещение. В стене расположена выходная дверь. Путь наверх ведёт в кабину.]];
}:with {
	Ephe { -"свет|освещение", description = "Неяркий свет синего спектра." };
	Path {
		-"кабина",
		desc = "Ты можешь подняться в кабину.";
		walk_to = 'moontech';
	};
	out_to = '#gate';
	door {
		-"дверь";
		nam = '#door';
		["before_Open,Close"] = [[Дверь управляется с помощью рычага.]];
		description = function(s)
			p [[Эта прямоугольная массивная дверь ведёт наружу.]]
			if s:hasnt'open' then
				p [[В лунном модуле нет шлюза, поэтому открытие двери означает разгерметизацию.]]
			else
				p [[В дверном проёме ты видишь пепельный свет лунной поверхности.]]
			end
			p [[Возле двери установлен красный рычаг.]];
			return false
		end;
	}:attr 'static,openable,scenery':with {
		obj {
			-"рычаг,красный рычаг";
			description = [[С помощью рычага можно управлять выходной дверью.]];
			before_Transfer = function(s, w) if w == me() or w ^ '@out_to' then mp:xaction("Pull", s) else return false end end;
			["before_Push,Pull"] = function(s)
				if not gravity then
					p [[В твоих планах на сегодня не было выхода в открытый космос.]]
					return
				elseif _'alex'.state == 5 then
					p [[Не стоит открывать дверь, пока модуль не сел на поверхность.]]
					return
				end
				if _'#door':hasnt 'open' then
					_'#door':attr 'open'
					p [[Ты открываешь дверь.]]
				else
					_'#door':attr '~open'
					p [[Ты закрываешь дверь.]]
				end
				return false
			end;
		}:attr 'static';
	};
	Careful {
		-"луноход";
		description = [[Сейчас луноход находится в сложенном состоянии.]];
		before_Enter = function(s)
			if here() ^ 'moontech' then
				p [[Кататься в луноходе ты будешь на Луне.]]
				return
			end
			return false
		end;
	}:attr 'container,transparent,enterable,~scenery';
	Careful {
		-"оборудование";
		description = function(s)
			if s:once'screw' then
				p [[Твоё внимание привлекает универсальная дрель.]]
				enable 'screw'
			else
				p [[С оборудованием всё в порядке.]]
			end
		end;
	}:attr'~scenery,static';
	obj {
		nam = 'screw';
		-"дрель|шуруповёрт|отвёртка";
		init_dsc = [[На стене закреплена дрель.]];
		description = [[Многофункциональная ручная дрель-шуруповёрт. Выполнена в форме пистолета.]];
	};
	Prop { -"стена|стены/мн" };
}
global 'docking' (false)
global 'turned' (false)
global 'faraway' (false)

local dirs = {
	n = 'север',
	s = 'юг',
	e = 'восток',
	w = 'запад'
}

room {
	nam = 'moonmod';
	dir = 'w';
	pos = 0;
	height = 273;
	speed = 0;
	vspeed = -5;
	curspeed = 0;
	title = 'лунный модуль';
	-"модуль,корабль|кабина";
	['before_Answer,Ring'] = function()
		if _'скафандр':has'worn' then
			if _'скафандр'.radio then
				p [[Для того чтобы поговорить по радио, просто попробуйте поговорить с Зарёй, Беркутом или Арго.]];
				return
			end
		end
		return false
	end;
	d_to = 'moontech';
	before_Any = function(s, ev, w)
		if ev == 'Exam' or ev == 'Smell' or ev == 'Listen' or ev == 'Look' or ev == 'Search' then
			return false
		end
		if w and  w ^ '#люк' and me():where()^'place' then
			p [[Ты пристёгнут ремнями.]]
			return
		end
		return false
	end;
	before_Listen = function(s)
		if _'alex'.state == 3 then
			p [[Ты слышишь аварийный сигнал бортового компьютера.]]
			return
		end
		if _'alex'.state == 5 then
			p [[Ты слышишь рёв двигателей.]]
			return
		end
		return false
	end;
	before_Wait = function(s)
		local m = s
		if m.pos >= 100 and m.vspeed < 0 and m.speed == 0 and m.height < 250 and m.height > 0 then
			walkin 'stage4'
			return
		end
		return false
	end;
	dsc = function(s)
		if s:once 'first' then
			p [[Ты и Александр, облачённые в скафандры, находитесь в кабине лунного модуля.]]
		else
			p [[Ты находишься в кабине лунного модуля.]]
		end
		_'#win':dsc()
		p [[Ты можешь спуститься вниз в технический отсек.]]
	end;
}:with {
	Path { -"технический отсек", desc = "Ты можешь спуститься в технический отсек.", walk_to = 'moontech' };
	Ephe { -"космос", description = [[Ты никогда не привыкнешь к этому зрелищу. Одновременно пугающему и прекрасному.]] };
	Distance { nam = 'клубы'; -"туман,пар,вспышк*|клубы/мн";
		description = function()
			if _'moonmod'.pos >= 100 then
				p [[Тумана больше нет.]]
				return
			end
			p [[Время от времени ты видишь в тумане яркие вспышки.]];
		end;
	}:disable();
	Careful {
		nam = '#win';
		-"окна,пейзаж*|окно";
		dsc = function()
			if gravity then
				p [[Сквозь трапециевидные окна виден лунный пейзаж.]]
				if _'alex'.state == 5 then
					local m = _'moonmod'
					if m.dir ~= 'e' or m.pos < 50 then
						p [[Ты видишь клубы розового тумана, скрывающего лунную поверхность!]]
					else
						if m.pos > 50 and m.pos < 100 then
							p [[Ты видишь как туман постепенно рассеивается.]]
						end
					end
				end
			else
				p [[Сквозь трапециевидные окна виден бездонный, чёрный космос.]]
			end
		end;
		description = function(s)
			p [[Окна лунного модуля достаточно большие и обеспечивают неплохой обзор.]]
			s:dsc()
		end;
	};
	Careful {
		nam = 'panel';
		-"панель управления,панель,прибор*|компьютер";
		prog = 1;
		daemon = function(s)
			local m = _'moonmod'
			m.height = m.height + (rnd(3) + m.vspeed)
			if m.height < 120 then
				if m.pos < 100 then
					p [[Садиться в таких условиях видимости -- безумие!]]
				elseif m.speed ~= 0 then
					p [[Для посадки нужно погасить горизонтальную скорость.]]
				else
					walkin 'stage4'
					return
				end
				p [[Ты сдвинул левую ручку вперёд и снова набрал высоту.]]
				m.vspeed = 0
				m.height = 120 + rnd(7)
			end
			if m.height > 512 then
				m.height = 512
			end
			m.curspeed = m.curspeed + m.speed*(rnd(5) + 2)
			if m.speed == 0 and m.curspeed > 0 then m.curspeed = 0 end
			if m.speed == 0 and m.curspeed < 0 then m.curspeed = 0 end
			if m.curspeed > 30 then m.curspeed = 30 + rnd(6) end
			if m.curspeed < -30 then m.curspeed = -30 + rnd(6) end
			if m.dir == 'e' then
				m.pos = m.pos + m.curspeed
			elseif m.dir == 'w' then
				m.pos = m.pos - m.curspeed
			end
			if m.pos < -100 then m.pos = -100 end
			if m.pos > 150 then m.pos = 150 end
		end;
		description = function(s)
			local progs = {
				"расстыковка";
				"нав. Пик Малаперта";
			}
			if gravity then
				pn ("Ориентация: ", dirs[_'moonmod'.dir])
				pn ("Высота: ", _'moonmod'.height, " м.")
				pn ("Горизонт. скорость ", _'moonmod'.curspeed, " м/с.")
				pn ("Вертик. скорость ", _'moonmod'.vspeed, " м/с.")
			end
			if s.prog then
				pn ("Программа: ", progs[s.prog])
				if _'#люк':has'open' then
					pn ("Внимание! Стыковочный люк: открыт")
				end
				if _'alex'.state == 3 then
					pn ("Внимание! Стыковочные замки: отказ")
				end
			end
			p [[На панели ты видишь кнопку запуска и отмены программы и две ручки управления: левая и правая.]]
		end;
	}:with {
		Careful { -"ручки", description = [[Эти ручки позволяют управлять двигателями модуля. Ты можешь двигать их: влево, вправо, вперёд и назад.]] };
		Careful {
			-"правая ручка,ручка,правая/но";
			description = [[Это ручка управления тангажом и креном.]];
			before_Turn = [[Ты можешь двигать ручку: вправо, влево, вперёд и назад.]];
			["before_Push,Pull"] = function(s)
				if gravity then
					if _'panel'.prog then
						p [[Сначала нужно перевести модуль в режим ручного управления.]]
						return
					end

					local m = _'moonmod'
					local d
					if mp.event == 'Push' then
						d = 1
						m.speed = m.speed + 1
						if m.speed > 2 then
							m.speed = 2
						end
					else
						d = -1
						m.speed = m.speed - 1
						if m.speed < 2 then
							m.speed = -2
						end
					end
					if m.speed == 0 then
						p [[Плавным движением ручки ты выровнял модуль.]]
					elseif d > 0 then
						if m.speed < 0 then
							p [[Плавным движением ручки ты уменьшил крен лунного модулья.]]
						else
							p [[Плавным движением ручки ты накренил лунный модуль вперёд.]];
						end
					else
						if m.speed > 0 then
							p [[Плавным движением ручки ты уменьшил крен лунного модуля.]]
						else
							p [[Плавным движением ручки ты накренил лунный модуль назад.]]
						end
					end
					return
				end
				if not docking then
					p [[Сначала надо удалиться от Арго на безопасное расстояние.]]
				else
					p [[Уверенным движением ручки ты развернул модуль на 180 градусов.]]
					turned = not turned
					if not turned then
						p [[Сейчас прямо по курсу находится Арго.]]
					else
						p [[Теперь Арго находится за кормой.]]
					end
				end
			end;
			["before_PushRight,PushLeft"] = function(s)
				if gravity then
					if _'panel'.prog then
						p [[Сначала нужно перевести модуль в режим ручного управления.]]
						return
					end
					local dirs = { 'w', 'n', 'e', 's' }
					local d = _'moonmod'.dir
					local ns = { w = 1, n = 2, e = 3, s = 4 }
					d = ns[d]
					if mp.event == 'PushRight' then
						d = d + 1
					else
						d = d - 1
					end
					if d <= 0 then d = 4 elseif d > 4 then d = 1 end
					_'moonmod'.dir = dirs[d]
					local names = { 'запад', 'север', 'восток', 'юг' }
					p ([[Плавным движением ручки ты развернул модуль на ]]..names[d]..".")
					return
				end
				if not docking then
					mp:xaction("Push", s);
				else
					p [[Ты не видишь смысла тратить топливо для вращения модуля.]]
				end
			end;
		};
		Careful {
			-"левая ручка,ручка,левая/но";
			description = [[Это ручка управления двигателями.]];
			before_Turn = [[Ты можешь двигать ручку: вправо, влево, вперёд и назад.]];
			before_Push = function(s)
				if gravity then
					if _'panel'.prog then
						p [[Сначала нужно перевести модуль в режим ручного управления.]]
						return
					end
					local m = _'moonmod'

					m.vspeed = m.vspeed + rnd(3)
					if m.vspeed > 7 then m.vspeed = 7 end
					p [[Плавным движением ручки ты изменил вертикальную скорость.]]
					return
				end
				if not docking then
					p [[Хочешь протаранить Арго?]]
				else
					p [[Ты толкнул ручку от себя.]]
					if not turned then
						docking = false
						faraway = false
						p [[Маневровые двигатели включились, дав импульс модулю на причаливание.]]
					else
						p [[Маневровые двигатели включились, дав импульс модулю на дальнейшее расхождение с Арго.]]
						faraway = true
					end
				end
			end;
			before_Transfer = function(s, w) if w == me() or w ^ '@out_to' then mp:xaction("Pull", s) else return false end end;
			["before_PushRight,PushLeft"] = function(s)
				if gravity then
					if _'panel'.prog then
						p [[Сначала нужно перевести модуль в режим ручного управления.]]
						return
					end
					p [[Плавным движением ручки ты сдвинул лунный модуль в сторону.]]
					return
				end
				if not docking then
					mp:xaction("Push", s);
				else
					p [[Ты не видишь смысла тратить топливо для смещения корабля в сторону.]]
				end
			end;
			["before_Pull"] = function(s,w)
				if gravity then
					if _'panel'.prog then
						p [[Сначала нужно перевести модуль в режим ручного управления.]]
						return
					end
					local m = _'moonmod'
					m.vspeed = m.vspeed - rnd(3)
					if m.vspeed < -7 then m.vspeed = -7 end
					p [[Плавным движением ручки ты изменил вертикальную скорость.]]
					return
				end
				if _'alex'.state < 3 then
					p [[Что ты делаешь? Расстыковка ещё не произведена!]]
					return
				end
				if docking then
					p [[Модуль уже удалился от Арго на достаточное расстояние.]]
				else
					docking = 1
					p [[Ты потянул ручку на себя. Маневровые двигатели включились, дав импульс модулю на отчаливание.]];
				end
			end;
		};
	};
	obj {
		-"место пилота,место|стойка|места/мн|стойки/мн";
		nam = 'place';
		title = 'в стойке';
		inside_dsc = function() p [[Ты пристёгнут с стойке пилота.]]; end;
		description = [[В кабине есть два места для пилотов. Космонавты весь полёт проводят стоя,
		пристегнувшись ремнями к специальным стойкам.]];
		before_LetIn = function(s)
			p [[Ты пристёгиваешься к своей стойке.]]
			place(me(), s)
		end;
		before_LetGo = function(s)
			p [[Тебе мешают ремни.]]
		end;
	}:attr'supporter,scenery,static,enterable':with {
		'belts';
	};
	Careful {
		nam = '#button';
		-"кнопка";
		description = [[Красная кнопка запуска хорошо заметна на панели управления.]];
		before_Push = function()
			if not _'panel'.prog then
				p "Программа не выбрана."
				return
			end
			if not me():where()^'place' then
				p [[Сначала нужно пристегнуться к своей стойке.]]
				return
			end
			if _'#люк':has'open' then
				p [[-- Внимание! Стыковочный люк открыт. Расстыковка невозможна! -- слышишь ты синтезированную речь бортового компьютера.]]
				return
			end
			if _'alex'.state == 2 then
				if _'Беркут'.ack then
					p [[Сначала нужно проверить радиосвязь.]]
					return
				end
				if _'скафандр':hasnt'worn' then
					p [[Хорошо бы сначала надеть скафандр.]]
					return
				end
				_'Арго'.ack = false
				_'Заря'.ack = false
				stage = 'locking'
				_'alex'.state = 3
				DaemonStop 'alex'
				p [[Ты нажимаешь кнопку.^-- Поехали!^Послышался тревожный сигнал компьютера. Снова неполадки?]]
			elseif _'alex'.state == 3 then
				p [[Ты нажимаешь кнопку.]]
				if _'болтик':inside'lock' then
					p [[Ничего не происходит!]]
				else
					_'alex'.state = 4
					_'panel'.prog = false
					p [[Лунный модуль вздрагивает. Замки сработали! Теперь нужно отлететь от Арго на безопасное расстояние и развернуться.]]
				end
			elseif _'alex'.state == 4 then
				if not turned then
					p [[Прежде чем активировать программу, лучше развернуть модуль и отвести его подальше от Арго.]]
					return
				end
				if not faraway then
					p [[Прежде чем активировать программу, лучше отвести модуль подальше от Арго.]]
					return
				end
				walkin 'stage3'
				return
			elseif _'alex'.state == 5 and _'panel'.prog then
				_'panel'.prog = false
				pn [[Ты включаешь режим ручного управления модулем.]]
				pn [[-- Командир, ручной режим. Начинаю мониторинг приборов! -- слышишь ты по радио голос Александра.]];
				DaemonStart 'alex'
				return
			elseif _'alex'.state == 1 then
				p [[Рано начинать расстыковку.]]
			else
				p [[Не стоит нажимать на кнопки просто так.]]
				return
			end
		end;
	};
	obj {
		-"Александр,Саша/мр";
		nam = 'alex';
		state = 1;
		radio = -1;
		daemon = function(s)
			if gravity then
				p ("-- Высота: ", _'moonmod'.height,".")
				p (" Вертикальная скорость: ", _'moonmod'.vspeed, ".")
				if _'moonmod'.curspeed ~= 0 then
					p (" Направление: ", dirs[_'moonmod'.dir], ".", " Скорость: ", _'moonmod'.curspeed)
				end
				pn()
				return
			end
			local radio = {
				"-- Проверка радиосвязи! -- голос Александра прозвучал непривычно близко. -- Арго, я Беркут. Как слышно?",
				"-- Беркут, я Аргро. Связь отличная. -- это отозвался Сергей из командного модуля. -- Проверяем связь с ЦУП. -- Заря, это Арго. Как связь?";
				"-- ... Арго, Заря. Слышу вас хорошо! -- ответ от Земли пришёл с заметной задержкой.";
				"-- Ястреб, я Беркут. Как связь? -- Александр ожидающе смотрит на тебя сквозь защитное стекло скафандра.";
			}
			if (s.ack or _'Арго'.ack or _'Заря'.ack) and time() % 4 == 1 then
				if _'скафандр':hasnt'worn' then
					return
				end
				if s.ack then
					p [[-- Ястреб, я Беркут. Ответьте! -- слышишь ты голос Александра по радиосвязи.]]
				elseif _'Арго'.ack then
					p [[-- Ястреб, я Арго. Ответь, командир!]]
				elseif _'Заря'.ack then
					p [[-- Ястреб, Ястреб. Я Заря. Как слышно?]]
				end
				return
			end
			if s.radio then
				s.radio = s.radio + 1
				if _'скафандр':hasnt'worn' and s.radio > 0 then
					p [[Александр машет тебе правой рукой и стучит левой по своему шлему. Нужно проверить связь.]]
					s.radio = s.radio - 1
					return
				end
				if s.radio < 1 then
					return
				end
				p (radio[s.radio])
				if s.radio == #radio then
					_'Беркут'.ack = true
					_'Заря'.ack = true
					_'Арго'.ack = true
					s.radio = false
				end
				return
			elseif not s.ack and not _'Заря'.ack and not _'Арго'.ack and s.state == 1 then
				s.state = 2
				p "-- Ястреб, Заря. Начинайте расстыковку."
				_'Заря'.ack = "-- Заря, я Ястреб. Начинаем расстыковку."
			end
		end;
		dsc = function(s)
			if s.state == 1 then
				p [[Александр возится у панели управления.]];
			elseif s.state == 2 then
				p [[Александр пристёгнут к стойке пилота.]]
			elseif s.state == 3 then
				p [[Александр, пристёгнутый к своей стойке, изучает показания приборов на панели управления.]]
			else
				p [[Здесь находится Александр.]]
			end
		end;
		description = function(s)
			p [[В скафандрах все космонавты похожи друг на друга.]]
		end;
	}:attr'animate';
	obj {
		-"Сергей,Серёжа";
		nam = '#serg';
		description = [[Сергей не выглядит весёлым. Всё то время, пока ситуация на "Луна-9" не прояснится, ему придётся ждать на орбите. А затем, если не потребуется экстренная эвакуация, Сергею предстоит одинокое возвращение на Землю.]];
		before_Talk = function(s)
			p [[-- Не скучай, Серёжа!^
			-- Для первого полёта я уже получил массу впечатлений.^
			-- Ладно, до связи!]]
		end;
	}:attr'animate,scenery';
	obj {
		-"люк";
		nam = '#люк';
		dsc = function(s)
			if s:has'open' then
				if not disabled '#serg' then
					p [[В открытый стыковочный люк заглядывает Сергей.]]
				end
			else
				p [[Стыковочный люк закрыт.]]
			end
		end;
		description = function(s)
			if not disabled 'locks' then
				p [[^Ты можешь осмотреть стыковочные замки.]]
			else
				p [[Небольшой круглый люк связывает командный модуль с лунным модулем. Было непросто протиснуться в него! К счастью, это не надо делать часто.]];
			end
			return false
		end;
		before_Open = function(s)
			if _'alex'.state > 3 then
				p [[Не стоит разгерметезировать лунный модуль.]]
				return
			end
			if _'alex'.state == 3 then
				_'locks':enable()
			end
			return false
		end;
		before_Close = function(s)
			if not _'скафандр'.radio then
				disable '#serg'
				_'скафандр'.radio = true
				DaemonStart 'alex'
				me().scope:add 'Беркут'
				me().scope:add 'Заря'
				me().scope:add 'Арго'
			end
			return false
		end;
		before_Enter = function(s)
			p  [[О командном модуле позаботится Сергей.]];
		end;
	}:attr'openable,open,static':with {
		Careful {
			nam = 'locks';
			-"стыковочные замки|замки";
			description = function(s)
				p [[Двенадцать стыковочных замков установлены по периметру стыковочного узла.]];
				if not disabled 'lock' then
					p [[Твоё внимание привлекает замок номер 3.]]
				else
					p [[По внешнему виду замков невозможно определить неполадки, даже если они и есть.]]
				end
			end;
		}:disable():with {
			Prop { -"узел" };
			Careful {
				nam = 'lock';
				-"стыковочный замок|замок,механизм|корпус";
				description = function(s)
					p [[Судя по телеметрии, проблема именно в этом замке.]]
					if s:hasnt'open' then
						p [[Замок закрыт корпусом.]];
					else
						p [[Ты рассматриваешь механизм.]]
						return false
					end
				end;
				before_LetGo = function(s, w) if w^'болтик' then _'болтик'.know = true end return false end;
				before_Close = function() return false end;
				['before_Open,Unlock,Attack'] = function(s, w)
					if s:has'open' then
						p [[Уже вскрыт.]]
						return
					end
					if not w then
						p [[Чем? Голыми руками это не получится.]]
						return
					end
					if not have(w) then
						p ([[Но у тебя с собой нет ]], w:noun'рд', [[!]])
						return
					end
					if not w ^ 'screw' then
						p ([[Идея интересная, но ]], w:noun(), [[ здесь не поможет.]])
						return
					end
					s:attr'open'
					p [[Ты вскрываешь корпус 3-го замка дрелью-шуруповёртом.]]
				end;
			}:attr'container,openable':disable():with {
				obj {
					nam = 'болтик';
					know = false;
					-"болтик,болт";
					init_dsc = [[В механизме привода замка застрял болтик.]];
					description = function(s)
						s.know = true;
						if s:where() ^ 'lock' then
							p [[Болтик застрял в механизме замка! Поэтому расстыковка не удалась!]]
						else
							p [[Небольшой болтик. Интересно, откуда он выпал?]]
						end
					end;
				}
			}
		}
	}
}
Ephe {
	-"Беркут";
	ack = false;
	nam = 'Беркут';
	before_Talk = function(s)
		if s.ack then
			p "-- Беркут, я Ястреб. Связь в норме."
			s.ack = false
			return
		end
		if _'alex'.radio then
			p "Ты не стал перебивать Александра."
			return
		end
		if _'alex'.state == 3 then
			if _'болтик'.know then
				p [[-- Беркут, это был болтик!^-- Интересно, откуда он выпал?^-- Хороший вопрос.]]
			else
				p [[-- Беркут, ты выяснил в чём проблема?^-- 3-й стыковочный замок не отвечает и автоматика прекращает процесс расстыковки!]]
			end
			_'lock':enable()
			return
		end
		if _'alex'.state == 4 then
			if not _'panel'.prog then
				p [[-- Беркут, активируй программу навигации!^-- Есть, командир!]]
				_'panel'.prog = 2
			else
				p [[-- Беркут, программа загружена?^-- Так точно!]]
			end
			return
		end
		if _'alex'.state == 5 then
			if _'moonmod'.pos >= 100 then
				p [[-- Беркут, кажется, вышли!^-- Да, командир, можно садиться!]];
			else
				p [[-- Беркут, ты видишь это?^-- Да, командир.]]
			end
			return
		end
		if _'alex':visible() then
			p [[-- Как настрой, Беркут?^-- Всё в порядке, командир!]]
		else
			p [[-- Беркут, я Ястреб. Как обстановка?^-- Ястреб, Беркут. Всё в порядке.]]
		end
	end;
}
Ephe {
	-"Заря";
	ack = false;
	nam = 'Заря';
	before_Talk = function(s)
		if _'alex'.radio then
			p "Ты не стал перебивать Александра."
			return
		end
		if s.ack then
			if type(s.ack) == 'string' then
				p(s.ack)
			else
				p "-- Заря, Ястреб на связи.^-- ... Ястреб, Заря. Принято."
			end
			s.ack = false
			return
		end
		if _'alex'.state == 3 then
			if _'болтик'.know then
				pn "-- Заря, я Ястреб. Я обнаружил болтик в 3-м замке."
				pn "-- Ястреб, я Заря. Вас понял."
			else
				pn "-- Заря, я Ястреб. Расстыковка не состоялась."
				pn "-- Ястреб, я Заря. Мы изучаем телеметрию. Нет данных по З-му стыковочному замку. Вероятно, проблема в нём. Может быть, замыкание датчика замка поможет."
				pn "-- Заря, Ястреб. Вас понял, приступаю."
			end
			_'lock':enable()
			return
		end
		if _'alex'.state == 4 then
			pn "-- Заря, это Ястреб. Расстыковка успешно осуществлена!"
			pn "... Ястреб, Заря желает вам успешной посадки!"
			return
		end
		if _'alex'.state == 5 then
			if _'moonmod'.pos >= 100 then
				pn "-- Заря, я Ястреб! Вышли из зоны явления. Садимся!"
				pm "... -- Ястреб, Заря желает вам успешного прилунения!"
				return
			end
			pn "-- Заря, я Ястреб. Что за преходящие лунные явления?"
			pn "... Ястреб, Заря. Вы должны уже видеть это. Мы наблюдаем розовые вспышки закрывающие пик, диаметром до 2-х километров."
			pn "-- Заря, я Ястреб. Вы понимаете что это такое?"
			pn "-- ... Ястреб, Заря. Не вполне. Возможно, это электростатические разряды в пыли. В любом случае, ЦУП принял решение не рисковать. Сажайте модуль восточнее запланированного места."
			pn "-- Заря, Ястреб. Вас понял."
			return
		end
		if _'alex'.state == 6 then
			if s:once'land' then
				pn "-- Заря. Ястреб. Мы сели!"
				pn "... -- Ястреб. Заря. Спасибо за отличную новость!"
				return
			end
		end
		p [[Сейчас нет необходимости связываться с Землёй.]]
	end;
}
Ephe {
	-"Арго";
	nam = 'Арго';
	ack = false;
	before_Talk = function(s)
		if _'alex'.radio then
			p "Ты не стал перебивать Александра."
			return
		end
		if s.ack then
			p "-- Арго, Ястреб на связи.^-- Ястреб, Арго. Принято!"
			s.ack = false
			return
		end
		if _'alex'.state == 3 then
			pn "-- Арго, Ястреб. Расстыковка не состоялась. Работаем над решением проблемы. Возможна разгерметизация. Оставайся в командном модуле.^-- Ястреб, Арго. Вас понял. На связи."
			return
		end
		if _'alex'.state == 4 then
			pn "-- Арго, Ястреб. Расстыковка произошла!"
			p "-- Ястреб, Арго."
			if not docking then
				pn "Вижу вас совсем рядом."
			elseif turned then
				pn "Вижу вас во всём великолепии! До встречи, командир!"
			else
				pn "Наблюдаю ваше удаление!"
			end
			return
		end
		if _'alex'.state == 5 or _'alex'.state == 6 then
			pn "Связи с Арго нет. Сейчас он облетает противоположную сторону Луны."
			return
		end
		p "Сейчас нет необходимости связываться с Сергеем."
	end;
}
cutscene {
	nam = 'stage4';
	enter = function(s)
		DaemonStop 'alex'
		DaemonStop 'panel'
	end;
	title = "Луна-9";
	text = {
	[[Найдя подходящую ровную поверхность ты погасил горизонтальную скорость и начал спуск.]],
	[[-- Высота 103, скорость 3.4, топливо -- в норме! -- всё так же докладывал показания приборов Александр.
	Но тебе это было уже ни к чему. Ты и так видел всё что было нужно. Твои руки замерли на ручках управления и, казалось, сами собой короткими точными движениями корректировали скорость снижения.]];
	[[ -- Высота 53, скорость 1.7, топливо -- в норме! Поднимается пыль!^
	А вот камень размером с автомобиль. Откуда он взялся? Ты сдвигаешь ручку управления двигателями влево и модуль послушно уходит в сторону.]];
	[[ -- Высота 17, скорость 0.9, топливо -- в норме. Везде пыль!^
	Интересно, зачем Александр сообщает про пыль. Ты и сам видишь, что видимость нулевая. Клубы лунной пыли
	разгоняемые реактивной струёй поднялись наверх и закрыли весь обзор.]],
	[[ -- Высота 6! Контакт! -- ты быстро выключаешь двигатель. С секунду вы напряжённо ждёте, пока модуль свободно падает. Удар! ... Вы на Луне!]];
	};
	exit = function(s)
		_'alex'.state = 6
		disable 'клубы'
		_'moonmod'.height = 0
		_'moonmod'.vspeed = 0
	end;
}
cutscene {
	nam = 'stage3';
	title = 'Луна-9';
	text = {
		[[Пока двигатель ревел под ногами, давая необходимый импульс для снижения орбиты, ты смотрел в иллюминаторы сквозь которые сиял голубой серп Земли. Ты думал о Ларисе и Артуре.]];
		[[Привязанный ремнями, падающий на серо-пепельную поверхность Луны, тебе казалось что ты окончательно уже во власти другого мира. Но представляя спящих жену и сына там, на Земле, ты понимал что разрыв иллюзорен.]];
		[[Место посадки находилось у самого Южного полюса на горе Малаперт у "Пика вечного света". Освещённость 89% времени, прямая видимость с Земли, запасы льда и возможность установки телескопа в тени кратера  -- удобные условия для первой лунной базы человечества.]];
		[[Наконец, Земля постепенно ушла из иллюминаторов. Модуль падал с орбиты. На высоте 3700 метров, он занимал уже почти вертикальное положение. Прошло всего около 15 минут спуска.]];
		[[... -- Ястреб, я Заря! Мы фиксируем на месте посадки преходящее лунное явление. Мы рекомендуем вам изменить место посадки. Как поняли?]];
		[[-- Какое ещё явление?... Заря, я Ястреб. Куда садиться? Решайте быстрее, мы почти на месте!]];
		[[-- ... Ястреб, Заря, берите восточнее, там чисто. Вы сами увидите это, ориентируйтесь визуально.^
		-- Заря, я Ястреб. Что я должен увидеть?^
		-- Борис, смотри!]]
	};
	exit = function()
		gravity = true;
		_'alex'.state = 5
		enable 'клубы'
		DaemonStart 'panel'
	end;
}
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
-- Во время запуска маршевого двигателя - сбой
-- Короткое замыкание клапана топливных баков контура А. Он не может открыться.
-- Нужно перейти в служебный модуль и перекрыть кран контура А и переключиться на контур B.
-- эпизод 2 -- отстыковка
-- эпизод 3 -- посадка
-- эпизод 4 - 1й день на базе
-- гора Малаперт, "Пик вечного света" у Южного полюса.
-- 89% светло, затенённые кратеры (лёд)
-- Кратер Малаперт имеет полигональную форму и практически полностью разрушен. Вал представляет собой нерегулярное кольцо пиков окружающих чашу кратера, западная часть вала перекрыта безымянным кратером. Юго-западная часть вала формирует возвышение в виде хребта вытянутого с востока на запад высотой около 5000 м неофициально именуемое пиком Малаперта (иногда Малаперт Альфа). Дно чаши пересеченное, со множеством холмов. Вследствие близости к южному полюсу часть кратера практически постоянно находится в тени, что затрудняет наблюдения.
-- На пике -- передатчик для связи с Землёй.
-- Там же -- солнечная батарея.
-- Собираемая конструкция - в тени кратера.

-- Эпизод 3
-- По радиомаякам идут пешком или едут к Луне-9
