# Increment a count in a dict.
# This has its own function to encapsulate some heinous bug workaround
# code.
function increment_word(words::Dict{String,Int}, word::String)
    if !haskey(words, word)
        words[word] = 0
    end

    # Workaround for julia hash on unicode string bug
    # Note that this code non-determnisically hits a julia bug involving
    # exceptions which may cause this exception to be uncaught.
    try 
        words[word] += 1
    catch
        # println("DICT LOOKUP FAIL (uncode string bug?)------------------------")
        # println(w)
    end
end

function increment_author_word(authors::Dict{String,Dict{String,Int}}, word::String, author::String)
    if !haskey(authors, author)
        authors[author] = Dict{String,Int}()
    end

    increment_word(authors[author], word)
end

function bogus_word(word::String)
    ismatch(r"^<.*>$", word)
end

# Sort of bad, since these can demarcate things inside real identifiers.
# But it also creates a ton of noise and doing this in a smart way seems annoying.
function strip_punct(word::String)
    word = replace(word, r"\(","")
    word = replace(word, r"\)","")
    word = replace(word, r"\.","")
    word = replace(word, r",","")
    word = replace(word, r"\"","")
    word = replace(word, r"\*","")
    word = replace(word, r"'","")
    word = replace(word, r"`","")
    word = replace(word, r"!","")
    word = replace(word, r"^1$","")
end

# Takes a full commit message, minus the commit hash.
# TODO: handle old-style merge commits with From:
function process_chunk(chunk::String, all_words::Dict{String,Int}, author_words::Dict{String,Dict{String,Int}}, num_author_commits::Dict{String,Int})
    exists_in_chunk = Dict{String, Bool}()

    # Ignore merge commits.
    if ismatch(r"^Merge:", chunk)
        return 0
    end
    
    author = ""
    author_match = match(r"^Author.*<(.*)@.*>\n",chunk)
    if author_match != nothing
        author = lowercase(author_match.captures[1])
    else
        # fails on non-standard email address formats. Not many of these.
        # Ignoring for now.
        # println("AUTHOR MATCH FAIL------------------------")
        # println(chunk)
    end
    # TODO: attribute some commits to other people.

    # println("DEBUG--------------------------CHUNK")
    first_line = search(chunk, '\n')                # strip Author
    second_line = search(chunk, '\n', first_line+1) # strip Date

    # search returns a BoundsError if not found, so we have to try/catch this.
    # Seems like an API mistake/bug since this isn't how search for a char
    # behaves
    chunk_words = Array(String,0)
    try
        sign_off = search(chunk,r"Signed-off-by:")[1]-1
        # println(chunk[second_line:sign_off])
        chunk_words = split(chunk[second_line:sign_off])
    catch
        # println(chunk[second_line:end])
        chunk_words = split(chunk[second_line:end])
    end

    increment_word(num_author_commits,author)

    for w in chunk_words
        if !bogus_word(w)
            exists_in_chunk[lowercase(strip_punct(w))] = true
        end
        # increment_author_word(author_words, w, author)
    end

    for (w,_) in exists_in_chunk
            increment_word(all_words, w)
            increment_author_word(author_words, w, author)
    end
    return 1
end

function sort_authors(num_author_commits::Dict{String,Int})
    # Make an array and use built-in sort on number of commits per author
    author_arr = Array((String,Int), length(num_author_commits))
    i = 1
    for (author,num) in num_author_commits
        author_arr[i] = (author,num)
        i += 1
    end
    sort!(author_arr,by= x -> -x[2])
end

# Horribly abusing tf-idf. This is really not what it's intended for.
function top_words_for_author(all_words::Dict{String,Int}, their_words::Dict{String,Int}, author::String, num_words::Int)
    word_arr = Array((String,Float64), length(their_words))
    i = 1
    for (word, count) in their_words
        try 
            # println("IDF: $word $count all: $num_words $(all_words[word])\n")
            ratio = (1+num_words) / all_words[word]
            idf = ratio > .1 ? 0 : log(ratio)
            tf_idf = count * idf
            word_arr[i] = (word, tf_idf)
        catch
            # Unicode string hash bug
            word_arr[i] = (word, 0)
        end
        i += 1
    end

    print("$author")
    sort!(word_arr,by= x -> -x[2])
    i = 0
    for (word, count) in word_arr
        print(",$word")
        i += 1
        if i > 20
            break
        end
    end
    println("")
end

function read_log(fname::String)
    author_words = Dict{String,Dict{String,Int}}()
    all_words = Dict{String,Int}()
    num_author_commits = Dict{String,Int}()
    num_chunks = 0

    f = open(fname)
    chunk = ""
    line = readline(f)
    while line != ""
        line = readline(f)
        # Start of new commit. Previous chunk is complete and should be processed.
        if ismatch(r"^commit ", line)
            num_chunks += process_chunk(chunk, all_words, author_words, num_author_commits)
            chunk = ""
        else
            chunk *= line
        end
    end
    
    sorted_authors = sort_authors(num_author_commits)
    for (author,count) in sorted_authors
        top_words_for_author(all_words, author_words[author], author, num_chunks)
    end
end

#println(read_log("linux-log-mini-recent"))
#println(read_log("linux-log-mini-old"))
print(read_log("linux-log"))
#print(read_log("linux-log-small"))