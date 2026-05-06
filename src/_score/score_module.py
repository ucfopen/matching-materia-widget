import re

from scoring.module import ScoreModule

VALID_CHARS = r'[^\w!@#$%^&*?=\-+<>,\.;:"\'\(\) \t|]'


class Matching(ScoreModule):
    def check_answer(self, log):
        question = self.get_question_by_item_id(log.item_id)
        if not question:
            return 0

        answer = question["answers"][0]["text"]
        possible_answers = []

        if log.value != "":
            given_answer = log.value
            expected_answer = question["assets"][2]
            possible_answers.append(
                expected_answer if expected_answer is not None else ""
            )

            for q in self.questions:
                if log.item_id != q.item_id and self.clean_compare(
                    question["questions"][0]["text"], q.data["questions"][0]["text"]
                ):
                    possible_answers.append(q.data["assets"][2])

        else:
            given_answer = log.text
            expected_answer = question["answers"][0]["text"]
            possible_answers.append(expected_answer)

            for q in self.questions:
                if log.item_id != q.item_id and self.clean_compare(
                    question["questions"][0]["text"], q.data["questions"][0]["text"]
                ):
                    possible_answers.append(q.data["answers"][0]["text"])

        for answer in possible_answers:
            if self.clean_compare(answer, given_answer):
                return 100

        return 0

    def clean_compare(self, source, target):
        source = re.sub(VALID_CHARS, "", source)
        target = re.sub(VALID_CHARS, "", target)

        source = source.upper().strip()
        target = target.upper().strip()

        return source == target
