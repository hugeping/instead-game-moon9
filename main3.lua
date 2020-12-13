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
	"по {noun}/дт : Ring",
	":Talk"
}
VerbExtendWord {
	"#Exit",
	"вернуться"
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
	"{noun}/дт : Answer",
	"на {ring} : Answer"
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

function game:before_Any(ev)
	if ev == 'Jump' or ev == 'JumpOver' then
		p [[В невесомости?]]
		return
	end
	if _'скафандр':has'worn' and (ev == 'Taste' or
		ev == 'Eat' or
		ev == 'Kiss' or
		ev == 'Talk') then
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
	p [[Тебя зовут Борис Громов. Тебе 43 года и ты -- космонавт.]];
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
		if me():inside('кресло') then
			p [[Ты уже пристёгнут.]]
			return
		end
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
			p [[Ты видишь, как яркие солнечные лучи проникают сквозь иллюминаторы]];
			if s.rot then
				p " и скользят по стенам."
			else
				p "."
			end
		end
		p [[Позади кресел расположен люк.]]
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
		if s.engine then
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
		-"радио";
		before_Ring = function(s)
			if not s.ack then
				if dark_side() then
					p [[Пока корабль плывёт над обратной стороной Луны связь с ЦУП невозможна.]]
				else
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
			s:daemonStop()
			return
		end;
		daemon = function(s)
			if s:once 'ack' then
				p [["Перемен, требуют наши сердца!..."^^]]
				pn [[-- Арго-3, Заря. Как слышно? Приём? Доложите обстановку.]]
				p [[Ты видишь, что Александр и Сергей проснулись и потягиваются на своих креслах, разминая мышцы.]]
				_'Александр'.sleep = false
				_'Сергей'.sleep = false
				s.ack = true
				return
			end
			if s.ack then
				if not dark_side() and time() % 3 == 1 and me():inroom()^'модуль' then
					pn [[-- Арго-3, Заря. Как слышно? Почему не выходите на связь?]]
					p [[-- Командир, надо {$fmt em|ответить}! -- беспокоится Александр.]]
				end
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
				if s:where().rot then
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
					if not s:where().A then
						p [[-- Сергей, что происходит?^-- Какая-то проблема. Что на компьютере?^-- Сейчас посмотрю!]];
					else
						p [[-- Проблема с клапаном подачи топлива!^
						-- Возможно, короткое замыкание в контуре! Я могу переключиться на контур B, только...^
						-- Что?^
						-- Нет гарантий, что при включении двигателя не откроется и клапан контура A, а тогда...^
						-- Что делать?^
						-- Сходить в агрегатный модуль и перекрыть клапан A.]]
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
					p [[-- Саша, что с орбитой?^
					-- Почти 2-я космическая... Будем болтаться как в цирке на батуте.]]
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
		dist = 2570;
		speed = 2.536;
		otime = 0;
		prog = false;
		start = start_time;
		fltime = start_time;
		-"компьютер,бортовой компьютер";
		dsc = function(s)
			if _'модуль'.engine == 1 then
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
			if not _'модуль'.rot then
				return -- todo
			end
			update_comp()
			if s.dist < 2200 and s:once'wake' then
				DaemonStart '#radio'
				p [[Внезапно, тишину командного отсека нарушает звук радио.^^
				"Вместо тепла зелень стекла^
				Вместо огня дым!"...^^
				Кто-то там в ЦУП решил быть оригинальным.]]
			end
		end;
	}:attr'static':with {
		Careful {
			-"кнопка";
			before_Push = function(s)
				local prog = _'comp'.prog
				if prog == 1 then
					if not dark_side() then
						p [[Нужно подождать, пока корабль зайдёт в тень. Иначе, нарушится термальный контроль, который поддерживается вращением.]]
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
					_'comp'.prog = false
					_'модуль'.marsh = true
					p [[Корабль вздрогнул. Со стороны служебного отсека послышался сильный и низкий гул. Это запустился маршевый двигатель. 1, 2, 3, 4, 5... секунд. Вдруг, гул прекратился так же внезапно, как и начался. Что-то пошло не так! Двигатель должен был проработать 17 секунд!]]
					_'comp'.speed = 2.398
					_'модуль'.engine = 1
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
	Path { -"агрегатный отсек,отсек,проход",
		desc = function(s)
			p "Ты можешь выйти в агрегатный отсек.";
		end;
		walk_to = '#дверь';
	};
	Careful {
		-"скафандры";
		description = [[Скафандры для выхода в открытый космос.]];
		before_Take = "Зачем тебе все скафандры?";
	}:attr'clothing,~scenery';
	obj {
		-"скафандр";
		nam = 'скафандр';
		dsc = function(s)
			if s:inroom() ^ 'sect2' then
				return
			end
			return false
		end;
		before_Disrobe = function(s)
			if here() ^ 'sect2' and _'#дверь':has'open'
				or here() ^ 'агрегатный отсек' then
				p [[Без скафандра ты умрёшь!]]
				return
			end
			return false
		end;
	}:attr'clothing';
}
room {
	nam = 'агрегатный отсек';
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
	pn ([[Скорость: ]], string.format("%.3f", _'comp'.speed), ' км/с');
	if _'модуль'.engine then
		_'модуль'.A = true
		p [[Клапан подачи топлива, контур A: ошибка]]
	end
	if _'comp'.prog then
		local progs = {
			"стабилизация";
			"разворот на 180";
			"вкл. маршевый двигатель";
		}
		pn ("Программа: ", progs[_'comp'.prog])
		p [[Ты видишь, что кнопка "выполнить" подсвечена красным.]]
	end
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
-- Во время запуска маршевого двигателя - сбой
-- Короткое замыкание клапана топливных баков контура А. Он не может открыться.
-- Нужно перейти в служебный модуль и перекрыть кран контура А и переключиться на контур B.
-- эпизод 2 -- посадка,
-- гора Малаперт, "Пик вечного света" у Южного полюса.
-- 89% светло, затенённые кратеры (лёд)
-- Кратер Малаперт имеет полигональную форму и практически полностью разрушен. Вал представляет собой нерегулярное кольцо пиков окружающих чашу кратера, западная часть вала перекрыта безымянным кратером. Юго-западная часть вала формирует возвышение в виде хребта вытянутого с востока на запад высотой около 5000 м неофициально именуемое пиком Малаперта (иногда Малаперт Альфа). Дно чаши пересеченное, со множеством холмов. Вследствие близости к южному полюсу часть кратера практически постоянно находится в тени, что затрудняет наблюдения.
-- На пике -- передатчик для связи с Землёй.
-- Там же -- солнечная батарея.
-- Собираемая конструкция - в тени кратера.

-- Эпизод 3
-- По радиомаякам идут пешком или едут к Луне-9
