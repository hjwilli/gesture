function [score, local_scores]=lscore(truth, pred)
%[score, local_scores]=lscore(truth, pred)
% Compute the sum of generalized Levenshtein distances between lines
% divided by the total number of tokens in truth.

% Isabelle Guyon -- isabelle@clopinet.com -- Oct. 2011

n=0;
score=0;
local_scores=zeros(length(truth),1);
for k=1:length(truth)
    local_scores(k)=levenshtein(truth{k}, pred{k});
    score=score+local_scores(k);
    n=n+length(truth{k});
end
score=score/n;
