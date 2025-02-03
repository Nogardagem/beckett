extends Resource

class_name TextGen

var word_data = {};
var used_words = {};
var weighted_word_weight = 100;

var word_counts = {};
var trio_data = {};
var word_weight = 2;
var uncommon_word_use_min = 5;

var beckett_protection = false; #whether to avoid using beckett in responses or whatever


var separators = [".", "!", "?"]; #characters that can end outputs
var anti_separators = ["..."];

var clear_chars = ["\""]; #characters to be removed from input

func _init(text_folder = null, _separators = separators, _clear_chars = clear_chars):
	randomize();
	
	if text_folder != null:
		process_folder(text_folder);
	
	separators = _separators;
	clear_chars = _clear_chars;
	

func process_folder(folder):
	var text = get_folder_text(folder);
	process_text(text);

func process_text(text):
	if text == "": return;
	
	for cha in clear_chars:
		text = text.replace(cha, "");
	
	var words = get_words_from_text(text, true);
	var words_without_spaces = [];
	for i in words.size():
		if words[i] != " ": words_without_spaces.append(words[i]);
	
	for word in words_without_spaces:
		if word in word_counts:
			word_counts[word] += 1;
		else:
			word_counts[word] = 1;
	
	if words_without_spaces.size() > 0:
		for i in words.size() - 2:
			add_word_data(words[i].to_lower(), words[i+1].to_lower(), words[i+2].to_lower());
	

func add_word_data(word_1, word_2, word_3):
	if !word_data.has(word_1):
		word_data[word_1] = {word_2: {word_3: 1}};
	elif !word_data[word_1].has(word_2):
		word_data[word_1][word_2] = {word_3: 1};
	elif !word_data[word_1][word_2].has(word_3):
		word_data[word_1][word_2][word_3] = 1;
	else:
		word_data[word_1][word_2][word_3] += 1;
	
	var w = [word_1, word_2, word_3];
	add_trio_data([word_1, word_2, null], w);
	add_trio_data([null, word_2, word_3], w);
	add_trio_data([word_1, null, word_3], w);
	
	add_trio_data([word_1, null, null], w);
	add_trio_data([null, word_2, null], w);
	add_trio_data([null, null, word_3], w);

func add_trio_data(words_nulled, w):
	if words_nulled in trio_data:
		trio_data[words_nulled].append(w);
	else:
		trio_data[words_nulled] = [w];

func make_wfc_sentence(input):
	input.replace("\r", "");
	var prompt = Array(input.to_lower().split(" "));
	print("Prompted with: " + input);
	var least_common = null;
	var least_common_amount = INF;
	
	var uncommon_limitless = null;
	var uncommon_limitless_amount = INF;
	
	var prompt_word = "";
	
	for word in prompt:
		if "beck" in word and beckett_protection: continue;
		if word in word_counts and word_counts[word] < least_common_amount and word_counts[word] >= uncommon_word_use_min:
			least_common = word;
			least_common_amount = word_counts[word];
		
		if word in word_counts and word_counts[word] < uncommon_limitless_amount:
			uncommon_limitless = word;
			uncommon_limitless_amount = word_counts[word];
		
	
	if least_common == null:
		if uncommon_limitless == null:
			least_common = word_counts.keys()[randi() % word_counts.keys().size()];
		else:
			least_common = uncommon_limitless;
		
	
	prompt_word = least_common;
	print("Used word: " + prompt_word);
	
	var sentence = [prompt_word];
	var possible = trio_data[[null, prompt_word, null]];
	possible = possible[randi() % possible.size()];
	
	if randi() % 2 == 0:
		sentence.push_front(possible[0]);
	else:
		sentence.push_back(possible[2]);
	
	while sentence.front() != " " or sentence.back() != " ":
		var dir = randi() % 2;
		if (dir == 0 and sentence.front() != " ") or (dir == 1 and sentence.back() == " "):
			possible = trio_data[[null, sentence[0], sentence[1]]];
			var new_words = [];
			for i in possible:
				var w = i[0];
				if w in prompt and (!("beck" in w) or !beckett_protection):
					for j in word_weight:
						new_words.append(w);
				else:
					new_words.append(w);
			
			sentence.push_front(new_words[randi() % new_words.size()]);
			
		else:
			possible = trio_data[[sentence[sentence.size() - 2], sentence.back(), null]];
			var new_words = [];
			for i in possible:
				var w = i[2];
				if w in prompt and (!("beck" in w) or !beckett_protection):
					for j in word_weight:
						new_words.append(w);
				else:
					new_words.append(w);
			
			sentence.push_back(new_words[randi() % new_words.size()]);
			
	
	while " " in sentence: sentence.erase(" ");
	
	print("Said: " + " ".join(sentence));
	
	return " ".join(sentence)# + " | created from word: " + prompt_word;

func get_words_from_text(text, track_words = false):
	var split_words = text.split(" ", false);
	var words = [" ", " "];
	
	if track_words:
		for word in split_words:
			var splat = word.split("\n");
			for i in splat.size():
				splat[i] = splat[i].replace(char(13),""); #replace func gets rid of carriage return
				splat[i] = splat[i].replace("\r", "");
			
			for i in splat.size():
				if splat[i].length() != 0:
					if splat[i].to_lower() in used_words:
						if splat[i] in used_words[splat[i].to_lower()]:
							used_words[splat[i].to_lower()][splat[i]] += 1;
						else:
							used_words[splat[i].to_lower()][splat[i]] = 1;
					else:
						used_words[splat[i].to_lower()] = {splat[i]: 1};
					
					
					words.append(splat[i].to_lower());
				
				var ends_anti = false;
				for anti in anti_separators:
					if splat[i].ends_with(anti):
						ends_anti = true;
						break;
				
				if splat[i].length() == 0 or (splat[i][splat[i].length() - 1] in separators and !ends_anti) or (splat.size() > 1 and i < splat.size() - 1):
					if !(words[words.size() - 1] == " "): words.append_array([" ", " "]);
	
	if !(words[words.size() - 1] == " "): words.append_array([" ", " "]);
	
	#print("processed '" + text + "' to get " + str(words))
	return words;

func get_folder_text(folder_path):
	var text_files = [] # An array to store the contents of all text files
	
	var dir = DirAccess.open(folder_path)
	if dir == null: return "";
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			# Skip directories
			file_name = dir.get_next()
			continue
		
		var file_path = folder_path + "/" + file_name;
		if file_name.ends_with(".txt"):
			var file_contents = FileAccess.get_file_as_string(file_path);
			text_files.append(file_contents);
	
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return "\n".join(text_files);
