import React from "react";
const humanizeDuration = require("humanize-duration");

export function ProposalsList({ proposals, userVotes, castVote, blockHeight, refreshProposalStates }) {

    const proposalStatusToString = (status) => {
        switch (status) {
            case "0":
                return "ACTIVE";
            case "1":
                return "DEFEATED"
            case "2":
                return "PASSED";
            case "3":
                return "EXECUTED";
        }
    }

    const voteStatusToString = (status) => {
        switch (status) {
            case "0":
                return "APPROVED";
            case "1":
                return "REJECTED"
        }
    }

    const toShortString = (value, maxLength = 30) => {
        const strValue = value.toString();
        return strValue.length > 31 ? strValue.slice(0, maxLength) + "..." : strValue;
    }

    const isVoteValid = (vote) => {
        if (!vote) return false;
        return !(vote.status.toString() === "0" && vote.weight.toString() === "0");
    }

    const timeLeft = (voteEnd) => {
        const averageBlockTime = 17000; // milliseconds
        const diff = +voteEnd - blockHeight;
        return diff <= 0 ? undefined : humanizeDuration(diff * averageBlockTime);
    }

    if (proposals?.length > 0 && userVotes?.length > 0) {
        return (
            <div className="row">
                <div className="col-12">
                    <p className="card-text">Proposals</p>
                    <button className="btn btn-primary mb-2" onClick={refreshProposalStates}>Refresh proposal states</button>
                    <div className="card-group">
                    {proposals.map((value, index) => {
                        return (
                            <div key={index} className="card col-4" style={{ maxWidth: "300px"}}>
                                <div className="card-body">
                                    <h5 className="card-title">{toShortString(value.title)}</h5>
                                    <h6 className="card-subtitle mb-2 text-muted">{toShortString(value.forumLink)}</h6>
                                    <p className="card-text">{toShortString(decodeURI(value.description), 200)}</p>

                                    <div className="card-text">For votes: {value.forVotes.toString()}</div>
                                    <div className="card-text">Against votes: {value.againstVotes.toString()}</div>
                                    <div className="card-text">Status: {proposalStatusToString(value.status.toString())}</div>
                                    { proposalStatusToString(value.status.toString()) === "ACTIVE" && timeLeft(value.voteEnd)
                                        && <div className="card-text">Time left: {timeLeft(value.voteEnd)}</div> }

                                        { isVoteValid(userVotes[index]?.vote) && (
                                            <>
                                                <div className="card-header mt-2">
                                                    Your vote:
                                                </div>
                                                <ul className="list-group list-group-flush">
                                                    <li className="list-group-item">Status: {voteStatusToString(userVotes[index].vote.status.toString())}</li>
                                                    <li className="list-group-item">Weight: {userVotes[index].vote.weight.toString()}</li>
                                                </ul>
                                            </>
                                        )}
                                            {
                                                proposalStatusToString(value.status.toString()) === "ACTIVE" && (
                                                    <>
                                                        <p className="mt-2">
                                                            { isVoteValid(userVotes[index]?.vote) ? "Change vote:" : ""}
                                                        </p>
                                                        <div>
                                                            {!isVoteValid(userVotes[index]?.vote) && (
                                                                <>
                                                                    <button type="button" className="btn btn-success mr-2" onClick={() =>  castVote(0, index)}>APPROVE</button>
                                                                    <button type="button" className="btn btn-danger mr-2" onClick={() => castVote(1, index)}>REJECT</button>
                                                                </>
                                                            )}
                                                            {isVoteValid(userVotes[index]?.vote) && (
                                                                <>
                                                                    {userVotes[index].vote.status.toString() !== "0" ? (
                                                                        <button type="button" className="btn btn-success mr-2" onClick={() =>  castVote(0, index)}>APPROVE</button>
                                                                    ) : (
                                                                        <button type="button" className="btn btn-danger mr-2" onClick={() => castVote(1, index)}>REJECT</button>
                                                                    )}
                                                                </>
                                                            )}
                                                        </div>
                                                    </>
                                                )
                                            }
                                </div>
                            </div>
                        )
                    })}
                    </div>
                </div>
            </div>
        );
    } else {
        return (
            <>No proposals...</>
        );
    }
}