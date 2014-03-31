keys = 1:12; 
chords = 1:7; 
inversions = 0:2;
chordNums = length(chords);

keyCNotes = [0 2 4 5 7 9 11];
keyMatrix = zeros(length(keys), length(chords));

for ii = 1:length(keys)
    keyMatrix(ii,:) = mod(keyCNotes+ii-1, 12);
end

transitionMatrix = [0, .069, 0, .289, .495, .138, .01;
            .208, 0, .098, .220, .232, .232, .01;
            .068, .113, 0, .371, .090, .349, .01;
            .527, 0, 0, 0, .347, .116, .01;
            .334, .074, 0, .285, 0, .297, .01;
            .140, .076, .076, .381, .317, 0, .01;
            .333, .094, 0, 0, .104, .469, 0];

numChords = 1500; 
chordList = zeros(numChords, 3); % COL1: Key, COL2: Chord #, COL3: Inversion

chordList(:,1) = 1; % Key is C, loop this for all keys
chordList(1,2) = 1; % Start with the I Chord
chordList(1,3) = 1; % Start with the 0th Inversion

rootNotesC = keyMatrix(1,:);
chords = zeros(chordNums, 3); % I, ii, iii, IV, V, vi, vii chords, root position

for ii=1:length(chords)
    chords(ii,:) = [rootNotesC(ii), rootNotesC(mod(ii+1,7)+1), rootNotesC(mod(ii+3,7)+1)];
    for jj=2:3
        if chords(ii,jj) < chords(ii,jj-1)
            chords(ii,jj) = chords(ii,jj) + 12;
        end
    end        
end

chordsFirstInv = chords - [zeros(chordNums, 2), 12*ones(chordNums, 1)]; % Chords in their first inversion
chordsFirstInv = [chordsFirstInv(:,3), chordsFirstInv(:,1), chordsFirstInv(:,2)];
chordsSecInv = chords - [zeros(chordNums, 1), 12*ones(chordNums,2)]; % Chords in their second inversion
chordsSecInv = [chordsSecInv(:,2), chordsSecInv(:,3), chordsSecInv(:,1)];

chordInvMatrices = cell(1,3); % Cell array of chords, chords first-inv, chords sec-inv
chordInvMatrices{1} = chords;
chordInvMatrices{2} = chordsFirstInv;
chordInvMatrices{3} = chordsSecInv;

distance = zeros(chordNums, chordNums, 3, 3);

% Distance is a 4-DIM matrix which can be used to determine which
% inversions can be used to provide the most natural chord progressions.
% The rows of distance correspond to the chord that you have currently
% played [1, 2, 3, 4, 5, 6, 7]. The columns correspond to the chord you want
% to play next. The 3rd dimension corresponds to the inversion of the chord
% you currently played [1, 2, 3]. The 4th dimension corresponds to the inversion
% of the chord you want to play next.

% For example, distance(1, 3, 2, 3) is the distance of the I chord, first
% inversion to the iii chords, second inversion.

for i=1:chordNums % Chord you're going from
    for j=1:chordNums % Chord you're going to
        for k=1:3 % Inversion you're going from
            for l=1:3 % Inversion you're going to
                distance(i,j,k,l) = sum(abs(chordInvMatrices{k}(i,:) - chordInvMatrices{l}(j,:)));
            end
        end
    end
end

for ii = 2:numChords
    previousChord = chordList(ii-1, 2); % Retrieve the previous chord number
    scalars = rand(1, 7);
    scaledTransition = transitionMatrix(previousChord,:).*scalars; % Use transMat to predict next chord
    nextChord = find(scaledTransition == max(scaledTransition));
    if length(nextChord) ~= 1
       nextChord = nextChord(1);
    end

    previousInversion = chordList(ii-1, 3);
    delta = [distance(previousChord, nextChord, previousInversion, 1), distance(previousChord, nextChord, previousInversion, 2), distance(previousChord, nextChord, previousInversion, 3)];
    nextInversion = find(delta == min(delta));
    if length(nextInversion) > 1
        nextInversion = nextInversion(1);
    end
   
    chordList(ii, 2) = nextChord; % Set next chord
    chordList(ii, 3) = nextInversion; % Set next inversion   
end

chordList = chordList - [zeros(numChords,2), ones(numChords,1)];

chords(1,:) = [1, 3, 5];
for ii = 2:7
    chords(ii,:) = chords(ii-1,:)+ones(1,3);
end

chordsFirstInv = chords - [zeros(chordNums, 2), 7*ones(chordNums, 1)]; % Chords in their first inversion
chordsFirstInv = [chordsFirstInv(:,3), chordsFirstInv(:,1), chordsFirstInv(:,2)];
chordsSecInv = chords - [zeros(chordNums, 1), 7*ones(chordNums,2)]; % Chords in their second inversion
chordsSecInv = [chordsSecInv(:,2), chordsSecInv(:,3), chordsSecInv(:,1)];

notesToSample = [1, 2, 4, 8];
chordUsed = zeros(1, 3);
nextChordUsed = zeros(1,3);
noteList = zeros(numChords*8, 1);
index = 1;

for ii = 1:numChords
    notesForChord = datasample(notesToSample, 1);
    chordNumber = chordList(ii, 2);
    chordInversion = chordList(ii, 3);
    if chordInversion == 0
        chordUsed = chords(chordNumber, :);
    elseif chordInversion == 1
        chordUsed = chordsFirstInv(chordNumber, :);
    elseif chordInversion == 2
        chordUsed = chordsSecInv(chordNumber, :);
    end
    
    chordNumber=chordList(ii+1,2);
    chordInversion=chordList(ii+1,3);
    if chordInversion == 0
        nextChordUsed = chords(chordNumber, :);
    elseif chordInversion == 1
        nextChordUsed = chordsFirstInv(chordNumber, :);
    elseif chordInversion == 2
        nextChordUsed = chordsSecInv(chordNumber, :);
    end
    
    notesToUse = zeros((max([chordUsed,nextChordUsed]) - min([chordUsed,nextChordUsed]) + 1),1);
    notesToUse(1) = min([chordUsed,nextChordUsed]);
    for kk=2:length(notesToUse)
        notesToUse(kk) = notesToUse(kk-1)+1;
    end
    
    for jj=index:index+notesForChord
        noteList(jj) = 
    end
    
    index = index + notesForChord;
    
    if ii == numChords - 1
        break;
    end
end