<?php

namespace Materia;
class Score_Modules_Matching extends Score_Module
{

	public $is_case_sensitive;
	const VALID_CHARS = '/[^\w!@#$%^&*?=\-+<>,\.;:"\'\(\) \t|]/';

	public function __construct($play_id, $inst, $play = null)
	{
		parent::__construct($play_id, $inst, $play);

		if (isset($inst->qset->data['options']['caseSensitive']) && $inst->qset->data['options']['caseSensitive'] == 1)
		{
			$this->is_case_sensitive = true;
		}
		else
		{
			$this->is_case_sensitive = false;
		}
	}

	// compares two string answers by sanitizing them first
	public function clean_compare($source, $target)
	{
		$source = preg_replace(self::VALID_CHARS, '', $source);
		$target = preg_replace(self::VALID_CHARS, '', $target);

		if ( ! $this->is_case_sensitive)
		{
			// we dont care about case, so just convert all to upper
			$source = strtoupper($source);
			$target = strtoupper($target);
		}

		$source = trim($source);
		$target = trim($target);

		return $source == $target;
	}

	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$question = $this->questions[$log->item_id];
			$possibleAnswers = [];

			if($log->value != '')
			{
				// answer is an audio asset & id
				$givenAnswer = $log->value;
				$expectedAnswer = $question->assets[2];
				$possibleAnswers[] = $expectedAnswer;

				// if another question contains duplicate question text (left side), the answer for that pair should also be valid
				foreach ($this->questions as $id => $q)
				{
					if ($id != $log->item_id && $this->clean_compare($q->questions[0]['text'], $question->questions[0]['text']))
					{
						$possibleAnswers[] = $q->assets[2];
					}
				}
			}
			else
			{
				// answer is a text answer
				$givenAnswer = $log->text;
				$expectedAnswer = $question->answers[0]['text'];
				$possibleAnswers[] = $expectedAnswer;

				// if another question contains duplicate question text (left side), the answer for that pair should also be valid
				foreach ($this->questions as $id => $q)
				{
					if ($id != $log->item_id && $this->clean_compare($q->questions[0]['text'], $question->questions[0]['text']))
					{
						$possibleAnswers[] = $q->answers[0]['text'];
					}
				}
			}

			foreach ($possibleAnswers as $answer)
			{
				if ($this->clean_compare($answer, $givenAnswer)) return 100;
			}
		}

		return 0;
	}
}
