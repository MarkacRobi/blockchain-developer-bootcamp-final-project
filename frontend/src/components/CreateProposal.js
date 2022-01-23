import React from "react";

export function CreateProposal({ createProposal }) {
    return (
        <div>
            <h4>Governance</h4>
            <form
                onSubmit={(event) => {
                    // This function just calls the transferTokens callback with the
                    // form's data.
                    event.preventDefault();

                    const formData = new FormData(event.target);
                    const title = formData.get("title");
                    const forumLink = formData.get("forum-link");
                    // encode URI to allow spaces and special chars
                    const description = encodeURI(formData.get("description"));

                    if (title && forumLink && description) {
                        createProposal(title, forumLink, description);
                    }
                }}
            >
                <div className="form-group">
                    <label>Title</label>
                    <input
                        name="title"
                        className="form-control"
                        type="text"
                        minLength="1"
                        maxLength="100"
                        required
                    />
                </div>
                <div className="form-group">
                    <label>Forum link</label>
                    <input
                        name="forum-link"
                        className="form-control"
                        type="text"
                        minLength="1"
                        maxLength="200"
                        required
                    />
                </div>
                <div className="form-group">
                    <label>Description</label>
                    <input className="form-control" type="text" minLength="10" maxLength="200" name="description" required />
                </div>
                <div className="form-group">
                    <input className="btn btn-primary" type="submit" value="Create proposal" />
                </div>
            </form>
        </div>
    );
}
